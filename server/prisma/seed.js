require('dotenv').config();
const bcrypt = require('bcryptjs');
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const hash = await bcrypt.hash('password123', 12);

  const admin = await prisma.user.upsert({
    where: { email: 'admin@mamo.id' },
    update: {},
    create: { email: 'admin@mamo.id', passwordHash: hash, role: 'admin', profile: { create: { fullName: 'Admin MAMO' } }, cart: { create: {} } },
  });

  const sellers = [];
  for (let i = 1; i <= 3; i++) {
    sellers.push(await prisma.user.upsert({
      where: { email: `penjual${i}@mamo.id` },
      update: {},
      create: { email: `penjual${i}@mamo.id`, passwordHash: hash, role: 'seller', profile: { create: { fullName: `Penjual ${i}`, phone: `0812345678${i}0` } }, cart: { create: {} } },
    }));
  }

  const buyer = await prisma.user.upsert({
    where: { email: 'pembeli@mamo.id' },
    update: {},
    create: { email: 'pembeli@mamo.id', passwordHash: hash, role: 'buyer', profile: { create: { fullName: 'Pembeli Satu' } }, cart: { create: {} } },
  });

  const campus = await prisma.campus.upsert({
    where: { id: 'campus-polines' },
    update: {},
    create: { id: 'campus-polines', name: 'Politeknik Negeri Semarang', city: 'Semarang', address: 'Jl. Prof. Sudarto, Tembalang', latitude: -7.0521, longitude: 110.4354 },
  });

  const catNames = ['Elektronik', 'Fashion', 'Buku & Alat Tulis', 'Kos & Furniture', 'Gaming', 'Olahraga'];
  const cats = [];
  for (const name of catNames) {
    cats.push(await prisma.category.upsert({
      where: { id: `cat-${name.toLowerCase().replace(/[^a-z0-9]+/g, '-')}` },
      update: {},
      create: { id: `cat-${name.toLowerCase().replace(/[^a-z0-9]+/g, '-')}`, name, icon: 'category' },
    }));
  }

  const products = [
    { name: 'Macbook Air M1 2020', price: 8250000, condition: 'used', cat: 0, loc: 'Semarang, Banyumanik' },
    { name: 'Kursi Kayu Jati 30x200 CM', price: 120000, condition: 'used', cat: 3, loc: 'Ngaliyan' },
    { name: 'Gamepad Fantech EOS PRO WGP15', price: 420000, condition: 'new', cat: 4, loc: 'Tembalang' },
    { name: 'Asus TUF DASH F15 2022', price: 9100000, condition: 'used', cat: 0, loc: 'Mijen' },
    { name: 'Everyday Canvas Backpack', price: 320000, condition: 'new', cat: 1, loc: 'Tembalang' },
    { name: 'Buku Kalkulus Purcell Edisi 9', price: 150000, condition: 'used', cat: 2, loc: 'Tembalang' },
    { name: 'Sepatu Lari Nike Revolution 6', price: 550000, condition: 'used', cat: 5, loc: 'Banyumanik' },
    { name: 'Monitor LG 24 inch IPS', price: 1350000, condition: 'used', cat: 0, loc: 'Tembalang' },
  ];

  for (let i = 0; i < products.length; i++) {
    const p = products[i];
    const seller = sellers[i % sellers.length];
    const id = `prod-${i + 1}`;
    await prisma.product.upsert({
      where: { id },
      update: {},
      create: {
        id, name: p.name, price: p.price, condition: p.condition,
        description: `${p.name} dalam kondisi ${p.condition === 'new' ? 'baru' : 'bekas terawat'}. COD sekitar ${p.loc}.`,
        stock: 3, status: 'active', sellerId: seller.id,
        categoryId: cats[p.cat].id, campusId: campus.id,
        location: p.loc, latitude: -7.05 + i * 0.005, longitude: 110.43 + i * 0.005,
        images: { create: [{ imageUrl: `https://picsum.photos/seed/${id}/600/600`, sortOrder: 0 }] },
      },
    });
  }

  console.log('Seed selesai: admin, 3 seller, 1 buyer, 6 kategori, 8 produk');
  console.log('Login: admin@mamo.id / penjual1@mamo.id / pembeli@mamo.id — password: password123');
}

main().catch((e) => { console.error(e); process.exit(1); }).finally(() => prisma.$disconnect());
