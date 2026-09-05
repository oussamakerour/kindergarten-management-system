const express = require('express');

const router = express.Router();

router.get('/', async (req, res) => { res.json({ success: true, message: 'Get payments' }); });
router.post('/', async (req, res) => { res.json({ success: true, message: 'Create payment' }); });
router.get('/:id', async (req, res) => { res.json({ success: true, message: 'Get payment' }); });
router.put('/:id', async (req, res) => { res.json({ success: true, message: 'Update payment' }); });
router.delete('/:id', async (req, res) => { res.json({ success: true, message: 'Delete payment' }); });

module.exports = router;
