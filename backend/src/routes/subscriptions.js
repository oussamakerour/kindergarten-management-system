const express = require('express');

const router = express.Router();

router.get('/', async (req, res) => { res.json({ success: true, message: 'Get subscriptions' }); });
router.post('/', async (req, res) => { res.json({ success: true, message: 'Create subscription' }); });
router.get('/:id', async (req, res) => { res.json({ success: true, message: 'Get subscription' }); });
router.put('/:id', async (req, res) => { res.json({ success: true, message: 'Update subscription' }); });
router.delete('/:id', async (req, res) => { res.json({ success: true, message: 'Delete subscription' }); });

module.exports = router;
