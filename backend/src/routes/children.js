const express = require('express');
const supabase = require('../config/database');

const router = express.Router();

// Placeholder routes for children
router.get('/', async (req, res) => {
  res.json({ success: true, message: 'Get children' });
});

router.post('/', async (req, res) => {
  res.json({ success: true, message: 'Create child' });
});

router.get('/:id', async (req, res) => {
  res.json({ success: true, message: 'Get child' });
});

router.put('/:id', async (req, res) => {
  res.json({ success: true, message: 'Update child' });
});

router.delete('/:id', async (req, res) => {
  res.json({ success: true, message: 'Delete child' });
});

module.exports = router;
