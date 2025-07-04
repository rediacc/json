// This script runs when MongoDB starts for the first time
// It creates a database and user with specific permissions

db = db.getSiblingDB(process.env.MONGO_DATABASE);

db.createUser({
  user: 'appuser',
  pwd: 'appPassword123!',
  roles: [
    {
      role: 'readWrite',
      db: process.env.MONGO_DATABASE
    }
  ]
});

// Create a sample collection
db.createCollection('users');

// Insert sample data
db.users.insertOne({
  name: 'Sample User',
  email: 'user@example.com',
  createdAt: new Date()
});