const SQLite = require('better-sqlite3');
const crypto = require('crypto');
const express = require('express');
const app = express();
const port = 3000;
const db = new SQLite(__dirname + '/../data/auth.db', { verbose: console.log });

// TODO client-side hashing? WebAssembly with Argon2 or SCrypt implementation
// in rust?

// TODO how to handle salt being unique? if random number generator accidentally
// creates the same salt again?
// TODO uid should be case-insensitive
const createUserTable = db.prepare(`CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uid TEXT NOT NULL UNIQUE,
  salt TEXT NOT NULL UNIQUE,
  pwd TEXT NOT NULL,
  created TEXT DEFAULT CURRENT_TIMESTAMP,
  edited TEXT
);`);

createUserTable.run();

// const dropUserTable = db.prepare('drop table users');
// dropUserTable.run();

const selectAllUsers = db.prepare('SELECT * FROM users');
const selectUser = db.prepare('SELECT * FROM users WHERE uid = ?');
const insertUser = db.prepare('insert into users (uid, salt, pwd) values ($uid, $salt, $pwd)');

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// TODO login, wrong password, forgot password, and password is locked error
// messages should all be the same.They should take the same amount of processing
// time too.
app.post('/auth/login', (req, res) => {
  const { uid, pwd } = req.body;
  // read username or password
  const user = selectUser.get(uid);
  // - send to create account
  // else
  // - salt and hash password
  const pass = crypto.scryptSync(
    pwd,
    user.salt || crypto.randomBytes(32).toString('hex'),
    64
  ).toString('hex');
  // if no user with uid
  // - check salted password against database entry
  if (!user || pass !== user.pwd) {
    return res.status(400).json({ error: 'Login failed: Invalid user credentials' });
  }
  res.json({ action: 'login', uid, pwd, user });
});

app.post('/auth/signup', (req, res) => {
  const { uid, pwd } = req.body;
  // read username and password
  let user = selectUser.get(uid);
  if (user) {
    return res.status(400).json({ error: 'user exists', user });
  }
  const salt = crypto.randomBytes(32).toString('hex');
  const pass = crypto.scryptSync(pwd, salt, 64).toString('hex');
  // salt and hash password
  insertUser.run({ uid, salt, pwd: pass });
  user = selectUser.get(uid);
  // enter username and salted password into database
  res.json({ action: 'signup', uid, pwd, user });
});

// for editing a user
app.post('/auth/user', (req, res) => {
  const { uid, pwd } = req.body;
  res.json({ action: 'post user', uid, pwd });
});

app.get('/auth/users', (req, res) => {
  // list all users in database
  res.json({ action: 'get users', users: selectAllUsers.all() });
});

app.listen(port, () => {
  console.log('listening on %o', port);
});
