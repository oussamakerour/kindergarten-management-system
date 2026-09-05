const express = require('express');

const router = express.Router();

router.get('/', async (req, res) => { res.json({ success: true, message: 'Get expenses' }); });
router.post('/', async (req, res) => { res.json({ success: true, message: 'Create expense' }); });
router.get('/:id', async (req, res) => { res.json({ success: true, message: 'Get expense' }); });
router.put('/:id', async (req, res) => { res.json({ success: true, message: 'Update expense' }); });
router.delete('/:id', async (req, res) => { res.json({ success: true, message: 'Delete expense' }); });

module.exports = router;
