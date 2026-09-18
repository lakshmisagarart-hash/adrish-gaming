const express = require("express");
const fs = require("fs");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 3000;

const DATA = path.join(__dirname, "data");
const PRODUCTS = path.join(DATA, "products.json");
const ORDERS = path.join(DATA, "orders.json");

const UPI_ID = "9733942789@nyes";
const UPI_NAME = "MITHU DAS";

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(express.static(path.join(__dirname, "public")));

function readJSON(file, fallback) {
  try {
    if (!fs.existsSync(file)) return fallback;
    return JSON.parse(fs.readFileSync(file, "utf8"));
  } catch {
    return fallback;
  }
}

function writeJSON(file, data) {
  fs.writeFileSync(file, JSON.stringify(data, null, 2));
}

function products() {
  return readJSON(PRODUCTS, []);
}

function orders() {
  return readJSON(ORDERS, []);
}

function saveOrders(data) {
  writeJSON(ORDERS, data);
}

function nextOrderId(list) {
  if (!list.length) return 10001;

  return Math.max(
    ...list.map(x => Number(x.id) || 10000)
  ) + 1;
}

/* =========================================================
   PRODUCTS
========================================================= */

app.get("/api/products", (req, res) => {
  const all = products();

  const q = String(req.query.q || "").toLowerCase();
  const level = String(req.query.level || "all");

  let result = all;

  if (q) {
    result = result.filter(p =>
      `${p.name} ${p.game} ${p.category} ${p.level}`
        .toLowerCase()
        .includes(q)
    );
  }

  if (level !== "all") {
    result = result.filter(p => p.level === level);
  }

  res.json({
    success: true,
    total: result.length,
    products: result.map(p => ({
      id: p.id,
      name: p.name,
      game: p.game,
      category: p.category,
      level: p.level,
      price: p.price,
      stock: p.stock,
      status: p.status
    }))
  });
});

/* =========================================================
   CREATE ORDER
========================================================= */

app.post("/api/orders", (req, res) => {
  const productId = Number(req.body.productId);
  const customer = String(req.body.customer || "Customer").trim();

  const list = products();

  const product = list.find(p => p.id === productId);

  if (!product) {
    return res.status(404).json({
      success: false,
      message: "Product not found"
    });
  }

  if (product.status !== "available" || product.stock < 1) {
    return res.status(400).json({
      success: false,
      message: "Out of stock"
    });
  }

  const allOrders = orders();

  const order = {
    id: nextOrderId(allOrders),

    productId: product.id,
    productName: product.name,

    customer,

    amount: Number(product.price),

    status: "awaiting_payment",
    paymentStatus: "pending",

    createdAt: new Date().toISOString()
  };

  allOrders.push(order);
  saveOrders(allOrders);

  /*
    Reserve one item.
    Credentials remain hidden until admin verifies payment.
  */
  product.stock = Math.max(0, product.stock - 1);

  if (product.stock === 0) {
    product.status = "sold_out";
  }

  writeJSON(PRODUCTS, list);

  const upiUrl =
    `upi://pay?pa=${encodeURIComponent(UPI_ID)}` +
    `&pn=${encodeURIComponent(UPI_NAME)}` +
    `&am=${encodeURIComponent(order.amount.toFixed(2))}` +
    `&cu=INR` +
    `&tn=${encodeURIComponent(
      "Adrish Gaming Order #" + order.id
    )}`;

  res.json({
    success: true,

    order: {
      id: order.id,
      product: order.productName,
      amount: order.amount,
      status: order.status,
      paymentStatus: order.paymentStatus
    },

    payment: {
      upiId: UPI_ID,
      name: UPI_NAME,
      upiUrl
    }
  });
});

/* =========================================================
   ORDER STATUS
========================================================= */

app.get("/api/orders/:id", (req, res) => {
  const id = Number(req.params.id);

  const order = orders().find(o => Number(o.id) === id);

  if (!order) {
    return res.status(404).json({
      success: false,
      message: "Order not found"
    });
  }

  const response = {
    id: order.id,
    product: order.productName,
    amount: order.amount,
    customer: order.customer,
    status: order.status,
    paymentStatus: order.paymentStatus,
    createdAt: order.createdAt
  };

  /*
    IMPORTANT:
    Credentials are ONLY returned after payment verification.
  */

  if (order.paymentStatus === "verified") {
    const item = products().find(
      p => p.id === order.productId
    );

    if (item) {
      response.credentials = {
        accountId: item.account_id,
        password: item.account_password
      };
    }
  }

  res.json({
    success: true,
    order: response
  });
});

/* =========================================================
   PAYMENT VERIFICATION
========================================================= */

app.post("/api/admin/orders/:id/verify", (req, res) => {
  const id = Number(req.params.id);

  const allOrders = orders();

  const index = allOrders.findIndex(
    o => Number(o.id) === id
  );

  if (index === -1) {
    return res.status(404).json({
      success: false,
      message: "Order not found"
    });
  }

  allOrders[index].paymentStatus = "verified";
  allOrders[index].status = "paid";
  allOrders[index].verifiedAt = new Date().toISOString();

  saveOrders(allOrders);

  res.json({
    success: true,
    message: "Payment verified"
  });
});

/* =========================================================
   ADMIN ORDERS
========================================================= */

app.get("/api/admin/orders", (req, res) => {
  res.json({
    success: true,
    orders: orders().reverse()
  });
});

/* =========================================================
   STATS
========================================================= */

app.get("/api/admin/stats", (req, res) => {
  const ps = products();
  const os = orders();

  res.json({
    products: ps.length,
    availableStock: ps.filter(
      p => p.status === "available"
    ).length,

    orders: os.length,

    paidOrders: os.filter(
      o => o.paymentStatus === "verified"
    ).length,

    pendingOrders: os.filter(
      o => o.paymentStatus !== "verified"
    ).length
  });
});

/* =========================================================
   PAGES
========================================================= */

app.get("/admin", (req, res) => {
  res.sendFile(
    path.join(__dirname, "public", "admin.html")
  );
});

app.get("*splat", (req, res) => {
  res.sendFile(
    path.join(__dirname, "public", "index.html")
  );
});

app.listen(PORT, () => {
  console.log("");
  console.log("🔥 ADRISH X TOOLS running on port " + PORT);
  console.log("💳 UPI:", UPI_ID);
});
