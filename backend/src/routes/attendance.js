const express = require('express');

const router = express.Router();

router.get('/', async (req, res) => { res.json({ success: true, message: 'Get attendance' }); });
router.post('/', async (req, res) => { res.json({ success: true, message: 'Create attendance' }); });
router.get('/:id', async (req, res) => { res.json({ success: true, message: 'Get attendance' }); });
router.put('/:id', async (req, res) => { res.json({ success: true, message: 'Update attendance' }); });
router.delete('/:id', async (req, res) => { res.json({ success: true, message: 'Delete attendance' }); });

module.exports = router;
