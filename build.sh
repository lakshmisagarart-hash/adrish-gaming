#!/data/data/com.termux/files/usr/bin/bash
set -e

echo "🔥 Building ADRISH X GAMING..."

rm -rf public server.js package.json data
mkdir -p public data

cat > package.json <<'EOF'
{
  "name":"adrish-x-gaming",
  "version":"1.0.0",
  "private":true,
  "scripts":{"start":"node server.js"},
  "dependencies":{"express":"^4.21.2"}
}
EOF

npm install

cat > data/products.json <<'EOF'
[
  {
    "id":1,
    "name":"Free Fire Diamond Pack",
    "game":"Free Fire",
    "category":"Top Up",
    "price":99,
    "stock":20,
    "featured":true
  },
  {
    "id":2,
    "name":"Free Fire Prime Account",
    "game":"Free Fire",
    "category":"Accounts",
    "price":499,
    "stock":1,
    "featured":true
  },
  {
    "id":3,
    "name":"BGMI UC Pack",
    "game":"BGMI",
    "category":"Top Up",
    "price":199,
    "stock":20,
    "featured":false
  },
  {
    "id":4,
    "name":"COD Mobile CP Pack",
    "game":"COD Mobile",
    "category":"Top Up",
    "price":149,
    "stock":20,
    "featured":false
  }
]
EOF

cat > data/orders.json <<'EOF'
[]
EOF

cat > server.js <<'EOF'
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
EOF

cat > public/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>ADRISH X GAMING</title>

<style>
*{box-sizing:border-box}
body{
 margin:0;
 background:#060711;
 color:#fff;
 font-family:Arial,sans-serif
}
header{
 position:sticky;
 top:0;
 z-index:20;
 background:#0b0d1aee;
 backdrop-filter:blur(15px);
 border-bottom:1px solid #20243a;
 padding:18px
}
.nav{
 max-width:1200px;
 margin:auto;
 display:flex;
 align-items:center;
 justify-content:space-between;
 gap:15px
}
.logo{
 font-size:22px;
 font-weight:900
}
.logo span{color:#8b5cf6}
.nav button,.hero button,.buy{
 border:0;
 background:#8b5cf6;
 color:white;
 padding:11px 16px;
 border-radius:11px;
 font-weight:bold
}
.hero{
 padding:75px 20px;
 text-align:center;
 background:
 radial-gradient(circle at 50% 0,#38247a 0,#15102f 28%,#060711 70%)
}
.hero h1{
 font-size:clamp(38px,8vw,72px);
 margin:0;
 font-weight:1000
}
.hero p{
 color:#a9aec2;
 font-size:18px
}
.search{
 width:min(700px,95%);
 padding:17px 20px;
 border-radius:15px;
 border:1px solid #303650;
 background:#0e1120;
 color:#fff;
 outline:none;
 font-size:16px
}
.wrap{
 max-width:1200px;
 margin:auto;
 padding:30px 20px
}
.filters{
 display:flex;
 gap:10px;
 overflow:auto;
 padding-bottom:20px
}
.filters button{
 white-space:nowrap;
 border:1px solid #2b3048;
 background:#111526;
 color:white;
 padding:10px 15px;
 border-radius:10px
}
.grid{
 display:grid;
 grid-template-columns:repeat(auto-fit,minmax(230px,1fr));
 gap:18px
}
.card{
 background:linear-gradient(145deg,#121629,#0d101d);
 border:1px solid #252a43;
 border-radius:20px;
 padding:20px;
 transition:.2s
}
.card:hover{
 transform:translateY(-5px);
 border-color:#8b5cf6;
 box-shadow:0 15px 45px #0008
}
.badge{
 color:#bca9ff;
 font-size:12px;
 font-weight:bold
}
.price{
 font-size:27px;
 font-weight:900;
 margin:18px 0
}
.stock{color:#8f96aa;font-size:13px}
.buy{width:100%;cursor:pointer}
.featured{
 border-color:#6d4bdc
}
.empty{
 text-align:center;
 color:#8f96aa;
 padding:50px
}
footer{
 padding:40px 20px;
 text-align:center;
 color:#71778e;
 border-top:1px solid #20243a
}
</style>
</head>

<body>

<header>
<div class="nav">
<div class="logo">🔥 ADRISH X <span>GAMING</span></div>
<button onclick="location.href='/admin'">👑 ADMIN</button>
</div>
</header>

<section class="hero">
<h1>LEVEL UP ⚡</h1>
<p>Gaming Marketplace • Top Ups • Items • Listings</p>
<input id="search" class="search"
placeholder="Search Free Fire, BGMI, skins..."
oninput="load()">
</section>

<main class="wrap">

<div class="filters">
<button onclick="setFilter('')">ALL</button>
<button onclick="setFilter('Free Fire')">FREE FIRE</button>
<button onclick="setFilter('BGMI')">BGMI</button>
<button onclick="setFilter('COD Mobile')">COD MOBILE</button>
<button onclick="setCategory('Top Up')">TOP UP</button>
<button onclick="setCategory('Accounts')">ACCOUNTS</button>
</div>

<h2>🔥 Marketplace</h2>
<div id="products" class="grid"></div>

</main>

<footer>
ADRISH X GAMING • Gaming Marketplace
</footer>

<script>
let game="";
let category="";

function setFilter(x){
 game=x;
 category="";
 load();
}

function setCategory(x){
 category=x;
 game="";
 load();
}

async function load(){

 const q=document.getElementById("search").value;

 const p=new URLSearchParams();
 if(q)p.set("q",q);
 if(game)p.set("game",game);
 if(category)p.set("category",category);

 const products=await fetch("/api/products?"+p).then(r=>r.json());

 document.getElementById("products").innerHTML=
 products.length?products.map(x=>`
 <div class="card ${x.featured?"featured":""}">
   <div class="badge">
    ${x.featured?"⭐ FEATURED • ":""}${x.game} • ${x.category}
   </div>
   <h2>${x.name}</h2>
   <div class="price">₹${x.price}</div>
   <div class="stock">Stock: ${x.stock}</div>
   <br>
   <button class="buy"
     onclick="buy(${x.id})"
     ${x.stock<=0?"disabled":""}>
     ${x.stock>0?"BUY NOW":"SOLD OUT"}
   </button>
 </div>
 `).join(""):"<div class='empty'>No products found.</div>";
}

async function buy(id){

 const buyer=prompt("Enter your name:");

 if(!buyer)return;

 const r=await fetch("/api/orders",{
   method:"POST",
   headers:{"Content-Type":"application/json"},
   body:JSON.stringify({
     product_id:id,
     buyer
   })
 });

 const d=await r.json();

 if(d.success)
   alert("✅ Order #"+d.order.id+" created!");
 else
   alert("❌ "+d.error);

 load();
}

load();
</script>

</body>
</html>
EOF

cat > public/admin.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>ADRISH X ADMIN</title>
<style>
body{
 margin:0;
 background:#060711;
 color:white;
 font-family:Arial
}
.wrap{
 max-width:1000px;
 margin:auto;
 padding:25px
}
.card{
 background:#111526;
 border:1px solid #292e47;
 border-radius:16px;
 padding:20px;
 margin:15px 0
}
input,select{
 width:100%;
 padding:13px;
 margin:7px 0 12px;
 border-radius:10px;
 border:1px solid #30364f;
 background:#090c17;
 color:white
}
button{
 padding:11px 15px;
 border:0;
 border-radius:10px;
 background:#8b5cf6;
 color:white;
 font-weight:bold;
 margin:4px
}
.stats{
 display:grid;
 grid-template-columns:repeat(3,1fr);
 gap:12px
}
.stat{
 background:#121629;
 border-radius:15px;
 padding:20px;
 text-align:center
}
</style>
</head>

<body>
<div class="wrap">

<h1>👑 ADRISH X ADMIN</h1>

<div id="stats" class="stats"></div>

<div class="card">
<h2>➕ Add Product</h2>

<input id="name" placeholder="Product name">
<input id="game" placeholder="Game">
<input id="category" placeholder="Category">
<input id="price" type="number" placeholder="Price">
<input id="stock" type="number" value="1" placeholder="Stock">

<select id="featured">
<option value="false">Normal</option>
<option value="true">Featured</option>
</select>

<button onclick="add()">ADD PRODUCT</button>
</div>

<h2>📦 Products</h2>
<div id="products"></div>

<h2>🧾 Orders</h2>
<div id="orders"></div>

</div>

<script>
async function refresh(){

 const s=await fetch("/api/stats").then(r=>r.json());

 document.getElementById("stats").innerHTML=`
 <div class="stat"><b>${s.products}</b><br>Products</div>
 <div class="stat"><b>${s.orders}</b><br>Orders</div>
 <div class="stat"><b>₹${s.sales}</b><br>Sales</div>
 `;

 const p=await fetch("/api/products").then(r=>r.json());

 document.getElementById("products").innerHTML=p.map(x=>`
 <div class="card">
 <b>${x.name}</b>
 <p>${x.game} • ${x.category} • ₹${x.price}</p>
 <button onclick="del(${x.id})">DELETE</button>
 </div>
 `).join("");

 const o=await fetch("/api/orders").then(r=>r.json());

 document.getElementById("orders").innerHTML=o.map(x=>`
 <div class="card">
 <b>Order #${x.id}</b>
 <p>${x.product}</p>
 <p>Buyer: ${x.buyer}</p>
 <p>Status: ${x.status}</p>
 <button onclick="status(${x.id},'Paid')">PAID</button>
 <button onclick="status(${x.id},'Delivered')">DELIVERED</button>
 </div>
 `).join("");
}

async function add(){

 await fetch("/api/products",{
   method:"POST",
   headers:{"Content-Type":"application/json"},
   body:JSON.stringify({
     name:name.value,
     game:game.value,
     category:category.value,
     price:price.value,
     stock:stock.value,
     featured:featured.value==="true"
   })
 });

 alert("✅ Product added");
 refresh();
}

async function del(id){

 if(!confirm("Delete product?"))return;

 await fetch("/api/products/"+id,{method:"DELETE"});
 refresh();
}

async function status(id,s){

 await fetch("/api/orders/"+id,{
   method:"PATCH",
   headers:{"Content-Type":"application/json"},
   body:JSON.stringify({status:s})
 });

 refresh();
}

refresh();
</script>
</body>
</html>
EOF

git init
git add .
git commit -m "ADRISH X GAMING"

echo ""
echo "===================================="
echo "🔥 ADRISH X GAMING READY"
echo "===================================="
echo ""
echo "Run:"
echo "cd ~/adrish-gaming && npm start"
echo ""
echo "Local test:"
echo "http://localhost:10000"
echo ""
echo "For public hosting:"
echo "Push this folder to GitHub and deploy it as a Node Web Service."
echo ""
