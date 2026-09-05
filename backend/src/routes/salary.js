const express = require('express');

const router = express.Router();

router.get('/', async (req, res) => { res.json({ success: true, message: 'Get salary' }); });
router.post('/', async (req, res) => { res.json({ success: true, message: 'Create salary' }); });
router.get('/:id', async (req, res) => { res.json({ success: true, message: 'Get salary' }); });
router.put('/:id', async (req, res) => { res.json({ success: true, message: 'Update salary' }); });
router.delete('/:id', async (req, res) => { res.json({ success: true, message: 'Delete salary' }); });

module.exports = router;
