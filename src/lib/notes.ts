import { supabase } from './supabase';
import type { Note } from './supabase';

export async function saveNote(title: string, content: string): Promise<Note | null> {
  try {
    const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
    
    const { data, error } = await supabase
      .from('notes')
      .upsert({
        title: title || 'Untitled',
        content: content,
        slug: slug
      })
      .select()
      .single();

    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Error al guardar la nota:', error);
    throw error;
  }
} 