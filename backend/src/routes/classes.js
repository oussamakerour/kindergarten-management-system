const express = require('express');
const supabase = require('../config/database');
const { isAdmin, isTeacher } = require('../middleware/auth');

const router = express.Router();

// Get all classes
router.get('/', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('classes')
      .select('*, teacher:teacher_id(full_name), assistant:assistant_teacher_id(full_name)')
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json({
      success: true,
      data
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching classes'
    });
  }
});

// Get class by ID
router.get('/:id', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('classes')
      .select('*, teacher:teacher_id(*), assistant:assistant_teacher_id(*)')
      .eq('id', req.params.id)
      .single();

    if (error) throw error;

    res.json({
      success: true,
      data
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching class'
    });
  }
});

// Create class (Admin only)
router.post('/', isAdmin, async (req, res) => {
  try {
    const { name, code, description, capacity, teacher_id, assistant_teacher_id, kindergarten_id, academic_year, age_group, room_number } = req.body;

    const { data, error } = await supabase
      .from('classes')
      .insert([{
        name,
        code,
        description,
        capacity,
        teacher_id,
        assistant_teacher_id,
        kindergarten_id,
        academic_year,
        age_group,
        room_number,
        status: 'active'
      }])
      .select()
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      message: 'Class created successfully',
      data
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error creating class'
    });
  }
});

// Update class
router.put('/:id', isAdmin, async (req, res) => {
  try {
    const { name, description, capacity, teacher_id, status } = req.body;

    const { data, error } = await supabase
      .from('classes')
      .update({
        name,
        description,
        capacity,
        teacher_id,
        status,
        updated_at: new Date()
      })
      .eq('id', req.params.id)
      .select()
      .single();

    if (error) throw error;

    res.json({
      success: true,
      message: 'Class updated successfully',
      data
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating class'
    });
  }
});

// Delete class
router.delete('/:id', isAdmin, async (req, res) => {
  try {
    const { error } = await supabase
      .from('classes')
      .delete()
      .eq('id', req.params.id);

    if (error) throw error;

    res.json({
      success: true,
      message: 'Class deleted successfully'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error deleting class'
    });
  }
});

module.exports = router;
