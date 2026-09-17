#!/data/data/com.termux/files/usr/bin/bash
set -e

cd ~/adrish-gaming

echo "🔥 ADRISH X GAMING — FULL UPDATE"
echo "================================"

# Git credentials ko future pushes ke liye remember karne ki setting
git config --global credential.helper store
git config --global user.name "ADRISH"
git config --global user.email "lakshmisagarart@gmail.com"

mkdir -p public data

# ==============================
# PACKAGE
# ==============================

cat > package.json <<'EOF'
{
  "name":"adrish-x-gaming",
  "version":"2.0.0",
  "private":true,
  "scripts":{
    "start":"node server.js"
  },
  "dependencies":{
    "express":"^4.21.2"
  }
}
EOF

npm install

# ==============================
# PRODUCTS — 150 PRODUCTS
# ==============================

node <<'NODE'
const fs=require("fs");

const games=[
 "Free Fire","BGMI","COD Mobile","Minecraft",
 "Roblox","Valorant","GTA","Gaming"
];

const cats=[
 "Top Up","Accounts","Skins","Bundles",
 "Gift Cards","Game Items","Battle Pass","Characters"
];

const names=[
 "Diamond Pack","UC Pack","CP Pack","Premium Pack",
 "Starter Pack","Pro Pack","Elite Pack","Ultimate Pack",
 "Legendary Bundle","Rare Bundle","Limited Bundle",
 "Weapon Skin","Character Pack","Battle Pass",
 "Prime Account","Rare Account","Gaming Voucher",
 "Gift Card","Special Bundle","Event Pack"
];

const prices=[
 49,79,99,149,199,249,299,349,399,499,
 599,699,799,999
];

let products=[];

for(let i=1;i<=150;i++){

 const game=games[(i-1)%games.length];
 const category=cats[(i-1)%cats.length];

 products.push({
   id:i,
   name:names[(i-1)%names.length]+" #"+i,
   game,
   category,
   price:prices[(i-1)%prices.length],
   stock:1+((i*7)%20),
   featured:i<=20
 });
}

fs.writeFileSync(
 "data/products.json",
 JSON.stringify(products,null,2)
);

if(!fs.existsSync("data/orders.json"))
 fs.writeFileSync("data/orders.json","[]");

console.log("✅ "+products.length+" products created");
NODE

# ==============================
# SERVER
# ==============================

cat > server.js <<'EOF'
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
EOF

# ==============================
# MAIN WEBSITE
# ==============================

cat > public/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport"
content="width=device-width,initial-scale=1">

<title>ADRISH X GAMING</title>

<style>
*{box-sizing:border-box}

body{
 margin:0;
 background:#05060d;
 color:white;
 font-family:Arial,sans-serif
}

header{
 position:sticky;
 top:0;
 z-index:20;
 padding:18px;
 background:#0b0d19ee;
 backdrop-filter:blur(18px);
 border-bottom:1px solid #252a42
}

.nav{
 max-width:1200px;
 margin:auto;
 display:flex;
 justify-content:space-between;
 align-items:center
}

.logo{
 font-size:23px;
 font-weight:1000
}

.logo span{
 color:#8b5cf6
}

.hero{
 padding:75px 20px;
 text-align:center;
 background:
 radial-gradient(circle at 50% 0,
 #422b91,#17112e 35%,#05060d 72%)
}

.hero h1{
 margin:0;
 font-size:clamp(42px,9vw,78px);
 font-weight:1000
}

.hero p{
 color:#aeb4c8;
 font-size:18px
}

.search{
 width:min(720px,95%);
 padding:17px 20px;
 border-radius:15px;
 border:1px solid #343a55;
 background:#101322;
 color:white;
 font-size:16px;
 outline:none
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

button{
 border:0;
 border-radius:11px;
 padding:11px 16px;
 background:#8b5cf6;
 color:white;
 font-weight:bold;
 cursor:pointer
}

.filters button{
 background:#111526;
 border:1px solid #2b3049;
 white-space:nowrap
}

.grid{
 display:grid;
 grid-template-columns:
 repeat(auto-fit,minmax(230px,1fr));
 gap:18px
}

.card{
 padding:20px;
 border-radius:20px;
 background:
 linear-gradient(145deg,#14182b,#0d101c);
 border:1px solid #292f48;
 transition:.2s
}

.card:hover{
 transform:translateY(-5px);
 border-color:#8b5cf6;
 box-shadow:0 15px 45px #0008
}

.badge{
 color:#bca8ff;
 font-size:12px;
 font-weight:bold
}

.price{
 font-size:28px;
 font-weight:1000;
 margin:17px 0
}

.stock{
 color:#8f96aa;
 font-size:13px
}

.buy{
 width:100%
}

.paybox{
 margin:50px auto 20px;
 max-width:600px;
 padding:30px;
 text-align:center;
 background:#111526;
 border:1px solid #303650;
 border-radius:22px
}

.qr{
 width:min(300px,90%);
 background:white;
 padding:8px;
 border-radius:15px
}

.upi{
 font-size:18px;
 font-weight:bold;
 color:#bdaaff;
 margin:15px
}

.upibtn{
 display:inline-block;
 padding:13px 20px;
 background:#8b5cf6;
 color:white;
 text-decoration:none;
 border-radius:11px;
 font-weight:bold
}

.note{
 color:#8f96aa;
 font-size:13px
}

footer{
 text-align:center;
 color:#70778b;
 padding:45px 20px
}
</style>
</head>

<body>

<header>
<div class="nav">
<div class="logo">
🔥 ADRISH X <span>GAMING</span>
</div>

<button onclick="location.href='/admin'">
👑 ADMIN
</button>
</div>
</header>

<section class="hero">

<h1>LEVEL UP ⚡</h1>

<p>
Gaming Marketplace • Top Ups • Accounts • Items
</p>

<input
 id="search"
 class="search"
 placeholder="Search Free Fire, BGMI, skins..."
 oninput="load()">

</section>

<main class="wrap">

<div class="filters">

<button onclick="setGame('')">
ALL
</button>

<button onclick="setGame('Free Fire')">
FREE FIRE
</button>

<button onclick="setGame('BGMI')">
BGMI
</button>

<button onclick="setGame('COD Mobile')">
COD MOBILE
</button>

<button onclick="setGame('Minecraft')">
MINECRAFT
</button>

<button onclick="setGame('Roblox')">
ROBLOX
</button>

<button onclick="setGame('Valorant')">
VALORANT
</button>

<button onclick="setCat('Top Up')">
TOP UP
</button>

<button onclick="setCat('Accounts')">
ACCOUNTS
</button>

</div>

<h2>🔥 Marketplace</h2>

<div id="products" class="grid"></div>

<!-- UPI PAYMENT -->

<div class="paybox">

<h2>💳 PAY WITH UPI</h2>

<p>
Scan the QR or use any UPI app.
</p>

<img
 class="qr"
 src="/qr.png"
 alt="UPI QR Scanner"
 onerror="this.style.display='none'">

<div class="upi">
UPI ID: 9733942789@nyes
</div>

<a
 class="upibtn"
 href="upi://pay?pa=9733942789@nyes&pn=MITHU%20DAS">
📲 PAY USING UPI APP
</a>

<p class="note">
After payment, keep your UTR/transaction ID.
</p>

</div>

</main>

<footer>
🔥 ADRISH X GAMING<br>
Gaming Marketplace
</footer>

<script>

let game="";
let category="";

function setGame(x){
 game=x;
 category="";
 load();
}

function setCat(x){
 category=x;
 game="";
 load();
}

async function load(){

 const params=new URLSearchParams();

 const q=document.getElementById(
   "search"
 ).value;

 if(q)params.set("q",q);
 if(game)params.set("game",game);
 if(category)params.set("category",category);

 const products=
 await fetch("/api/products?"+params)
 .then(r=>r.json());

 document.getElementById("products").innerHTML=
 products.length?

 products.map(p=>`

 <div class="card">

 <div class="badge">
 ${p.featured?"⭐ FEATURED • ":""}
 ${p.game} • ${p.category}
 </div>

 <h2>${p.name}</h2>

 <div class="price">
 ₹${p.price}
 </div>

 <div class="stock">
 Stock: ${p.stock}
 </div>

 <br>

 <button
 class="buy"
 onclick="buy(${p.id})"
 ${p.stock<=0?"disabled":""}>

 ${p.stock>0?"BUY NOW":"SOLD OUT"}

 </button>

 </div>

 `).join("")

 :"No products found.";
}

async function buy(id){

 const buyer=prompt(
   "Enter your name:"
 );

 if(!buyer)return;

 const r=await fetch(
   "/api/orders",
   {
     method:"POST",
     headers:{
       "Content-Type":"application/json"
     },
     body:JSON.stringify({
       product_id:id,
       buyer
     })
   }
 );

 const d=await r.json();

 if(d.success){

   alert(
    "Order #"+d.order.id+
    " created!\\n"+
    "Pay via UPI: 9733942789@nyes"
   );

 }else{

   alert("❌ "+d.error);

 }

 load();
}

load();

</script>

</body>
</html>
EOF

# ==============================
# ADMIN
# ==============================

cat > public/admin.html <<'EOF'
<!DOCTYPE html>
<html>
<head>
<meta name="viewport"
content="width=device-width,initial-scale=1">

<title>ADRISH X ADMIN</title>

<style>
body{
 margin:0;
 background:#05060d;
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
 border:1px solid #292f48;
 border-radius:17px;
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
 grid-template-columns:
 repeat(3,1fr);
 gap:12px
}

.stat{
 background:#121629;
 padding:20px;
 border-radius:15px;
 text-align:center
}
</style>
</head>

<body>

<div class="wrap">

<h1>👑 ADRISH X ADMIN</h1>

<p>ADRISH X GAMING MARKET</p>

<div id="stats" class="stats"></div>

<div class="card">

<h2>➕ Add Product</h2>

<input id="name"
placeholder="Product name">

<input id="game"
placeholder="Game">

<input id="category"
placeholder="Category">

<input id="price"
type="number"
placeholder="Price">

<input id="stock"
type="number"
value="1">

<select id="featured">
<option value="false">
Normal
</option>

<option value="true">
Featured
</option>
</select>

<button onclick="add()">
ADD PRODUCT
</button>

</div>

<h2>📦 Products</h2>

<div id="products"></div>

<h2>🧾 Orders</h2>

<div id="orders"></div>

</div>

<script>

async function refresh(){

 const s=
 await fetch("/api/stats")
 .then(r=>r.json());

 document.getElementById(
 "stats"
 ).innerHTML=`

 <div class="stat">
 <b>${s.products}</b>
 <br>Products
 </div>

 <div class="stat">
 <b>${s.orders}</b>
 <br>Orders
 </div>

 <div class="stat">
 <b>₹${s.sales}</b>
 <br>Sales
 </div>
 `;

 const p=
 await fetch("/api/products")
 .then(r=>r.json());

 document.getElementById(
 "products"
 ).innerHTML=p.map(x=>`

 <div class="card">

 <b>${x.name}</b>

 <p>
 ${x.game} •
 ${x.category} •
 ₹${x.price} •
 Stock ${x.stock}
 </p>

 <button
 onclick="del(${x.id})">
 DELETE
 </button>

 </div>

 `).join("");

 const o=
 await fetch("/api/orders")
 .then(r=>r.json());

 document.getElementById(
 "orders"
 ).innerHTML=o.map(x=>`

 <div class="card">

 <b>
 Order #${x.id}
 </b>

 <p>
 ${x.product} —
 ₹${x.price}
 </p>

 <p>
 Buyer: ${x.buyer}
 </p>

 <p>
 UPI: ${x.upi_id}
 </p>

 <p>
 Status: ${x.status}
 </p>

 <button
 onclick="status(${x.id},'Paid')">
 PAYMENT VERIFIED
 </button>

 <button
 onclick="status(${x.id},'Delivered')">
 DELIVERED
 </button>

 </div>

 `).join("");
}

async function add(){

 await fetch(
 "/api/products",
 {
  method:"POST",
  headers:{
   "Content-Type":"application/json"
  },
  body:JSON.stringify({
   name:name.value,
   game:game.value,
   category:category.value,
   price:price.value,
   stock:stock.value,
   featured:featured.value
  })
 }
 );

 alert("✅ Product added");

 refresh();
}

async function del(id){

 if(!confirm(
  "Delete product?"
 ))return;

 await fetch(
  "/api/products/"+id,
  {method:"DELETE"}
 );

 refresh();
}

async function status(id,s){

 await fetch(
 "/api/orders/"+id,
 {
  method:"PATCH",
  headers:{
   "Content-Type":"application/json"
  },
  body:JSON.stringify({
   status:s
  })
 }
 );

 refresh();
}

refresh();

</script>

</body>
</html>
EOF

# ==============================
# QR IMAGE
# ==============================

echo ""
echo "📷 Looking for your QR image..."

QR=""

for f in \
 "$HOME/storage/downloads/1000093239.png" \
 "$HOME/storage/shared/1000093239.png" \
 "/sdcard/Download/1000093239.png" \
 "/sdcard/1000093239.png"
do
 if [ -f "$f" ]; then
   QR="$f"
   break
 fi
done

if [ -n "$QR" ]; then
 cp "$QR" public/qr.png
 echo "✅ QR scanner added"
else
 echo "⚠️ QR image not found."
 echo "Save the scanner image to Downloads as:"
 echo "1000093239.png"
 echo "Then run this command:"
 echo "cp ~/storage/downloads/1000093239.png ~/adrish-gaming/public/qr.png"
fi

# ==============================
# GIT
# ==============================

git add .

git commit -m "ADRISH X GAMING full marketplace update" || true

echo ""
echo "🚀 Pushing to GitHub..."
echo ""

git push origin main

echo ""
echo "======================================"
echo "🔥 ADRISH X GAMING UPDATED"
echo "======================================"
echo ""
echo "🌐 https://adrish-gaming.onrender.com/"
echo "👑 https://adrish-gaming.onrender.com/admin"
echo ""
echo "Render should automatically deploy."
echo ""
