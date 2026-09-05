const express = require('express');

const router = express.Router();

router.get('/', async (req, res) => { res.json({ success: true, message: 'Get activities' }); });
router.post('/', async (req, res) => { res.json({ success: true, message: 'Create activity' }); });
router.get('/:id', async (req, res) => { res.json({ success: true, message: 'Get activity' }); });
router.put('/:id', async (req, res) => { res.json({ success: true, message: 'Update activity' }); });
router.delete('/:id', async (req, res) => { res.json({ success: true, message: 'Delete activity' }); });

module.exports = router;
