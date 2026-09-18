const express=require("express");
const fs=require("fs");
const path=require("path");

const app=express();
const PORT=process.env.PORT||10000;

const DATA=path.join(__dirname,"data");
const PRODUCTS=path.join(DATA,"products.json");
const ORDERS=path.join(DATA,"orders.json");

app.use(express.json());
app.use(express.urlencoded({extended:true}));
app.use(express.static("public"));

function read(file){
 try{
   return JSON.parse(fs.readFileSync(file,"utf8"));
 }catch{
   return [];
 }
}

function write(file,data){
 fs.writeFileSync(file,JSON.stringify(data,null,2));
}

app.get("/api/products",(req,res)=>{

 let products=read(PRODUCTS);
 const {q,game,category}=req.query;

 if(q){
   const s=q.toLowerCase();

   products=products.filter(p=>
     p.name.toLowerCase().includes(s) ||
     p.game.toLowerCase().includes(s) ||
     p.category.toLowerCase().includes(s)
   );
 }

 if(game)
   products=products.filter(p=>p.game===game);

 if(category)
   products=products.filter(p=>p.category===category);

 res.json(products);
});

app.post("/api/products",(req,res)=>{

 const products=read(PRODUCTS);

 const product={
   id:Date.now(),
   name:String(req.body.name||"Product"),
   game:String(req.body.game||"Gaming"),
   category:String(req.body.category||"Other"),
   price:Number(req.body.price||0),
   stock:Number(req.body.stock||1),
   featured:req.body.featured==="true"
 };

 products.push(product);
 write(PRODUCTS,products);

 res.json({success:true,product});
});

app.delete("/api/products/:id",(req,res)=>{

 const products=read(PRODUCTS)
   .filter(p=>p.id!=req.params.id);

 write(PRODUCTS,products);

 res.json({success:true});
});

app.post("/api/orders",(req,res)=>{

 const products=read(PRODUCTS);
 const orders=read(ORDERS);

 const product=products.find(
   p=>p.id==req.body.product_id
 );

 if(!product)
   return res.status(404).json({
     error:"Product not found"
   });

 if(product.stock<=0)
   return res.status(400).json({
     error:"Out of stock"
   });

 product.stock--;

 const order={
   id:Date.now(),
   product_id:product.id,
   product:product.name,
   game:product.game,
   buyer:String(req.body.buyer||"Guest"),
   price:product.price,
   payment:"UPI",
   upi_id:"9733942789@nyes",
   status:"Payment Pending",
   created_at:new Date().toISOString()
 };

 orders.push(order);

 write(PRODUCTS,products);
 write(ORDERS,orders);

 res.json({
   success:true,
   order
 });
});

app.get("/api/orders",(req,res)=>{
 res.json(read(ORDERS).reverse());
});

app.patch("/api/orders/:id",(req,res)=>{

 const orders=read(ORDERS);

 const order=orders.find(
   o=>o.id==req.params.id
 );

 if(!order)
   return res.status(404).json({
     error:"Order not found"
   });

 order.status=String(
   req.body.status||order.status
 );

 write(ORDERS,orders);

 res.json({success:true});
});

app.get("/api/stats",(req,res)=>{

 const products=read(PRODUCTS);
 const orders=read(ORDERS);

 res.json({
   products:products.length,
   orders:orders.length,
   sales:orders.reduce(
     (sum,o)=>sum+Number(o.price||0),0
   )
 });
});

app.get("/admin",(req,res)=>{
 res.sendFile(
   path.join(__dirname,"public/admin.html")
 );
});

app.get("*",(req,res)=>{
 res.sendFile(
   path.join(__dirname,"public/index.html")
 );
});

app.listen(PORT,"0.0.0.0",()=>{
 console.log("");
 console.log("🔥 ADRISH X GAMING ONLINE");
 console.log("PORT: "+PORT);
 console.log("");
});
