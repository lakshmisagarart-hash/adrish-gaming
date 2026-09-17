const express=require("express");
const fs=require("fs");
const path=require("path");

const app=express();
const PORT=process.env.PORT||10000;

const productsFile=path.join(__dirname,"data/products.json");
const ordersFile=path.join(__dirname,"data/orders.json");

app.use(express.json());
app.use(express.static(path.join(__dirname,"public")));

function read(file){
  return JSON.parse(fs.readFileSync(file,"utf8"));
}

function write(file,data){
  fs.writeFileSync(file,JSON.stringify(data,null,2));
}

app.get("/api/products",(req,res)=>{
  let products=read(productsFile);
  const {q,game,category}=req.query;

  if(q){
    const s=q.toLowerCase();
    products=products.filter(p=>
      p.name.toLowerCase().includes(s)||
      p.game.toLowerCase().includes(s)||
      p.category.toLowerCase().includes(s)
    );
  }

  if(game) products=products.filter(p=>p.game===game);
  if(category) products=products.filter(p=>p.category===category);

  res.json(products);
});

app.post("/api/products",(req,res)=>{
  const products=read(productsFile);
  const body=req.body;

  const product={
    id:Date.now(),
    name:body.name,
    game:body.game,
    category:body.category,
    price:Number(body.price),
    stock:Number(body.stock||1),
    featured:Boolean(body.featured)
  };

  products.push(product);
  write(productsFile,products);

  res.json({success:true,product});
});

app.delete("/api/products/:id",(req,res)=>{
  let products=read(productsFile);
  products=products.filter(p=>p.id!=req.params.id);
  write(productsFile,products);
  res.json({success:true});
});

app.post("/api/orders",(req,res)=>{
  const products=read(productsFile);
  const orders=read(ordersFile);

  const product=products.find(p=>p.id==req.body.product_id);

  if(!product)
    return res.status(404).json({error:"Product not found"});

  if(product.stock<=0)
    return res.status(400).json({error:"Out of stock"});

  product.stock--;

  const order={
    id:Date.now(),
    product_id:product.id,
    product:product.name,
    buyer:req.body.buyer||"Guest",
    price:product.price,
    status:"Pending",
    created_at:new Date().toISOString()
  };

  orders.push(order);

  write(productsFile,products);
  write(ordersFile,orders);

  res.json({success:true,order});
});

app.get("/api/orders",(req,res)=>{
  res.json(read(ordersFile).reverse());
});

app.patch("/api/orders/:id",(req,res)=>{
  const orders=read(ordersFile);
  const order=orders.find(o=>o.id==req.params.id);

  if(!order)
    return res.status(404).json({error:"Order not found"});

  order.status=req.body.status||order.status;
  write(ordersFile,orders);

  res.json({success:true});
});

app.get("/api/stats",(req,res)=>{
  const products=read(productsFile);
  const orders=read(ordersFile);

  res.json({
    products:products.length,
    orders:orders.length,
    sales:orders.reduce((a,o)=>a+Number(o.price||0),0)
  });
});

app.get("*",(req,res)=>{
  res.sendFile(path.join(__dirname,"public/index.html"));
});

app.listen(PORT,"0.0.0.0",()=>{
  console.log("");
  console.log("🔥 ADRISH X GAMING ONLINE");
  console.log("PORT:",PORT);
  console.log("");
});
