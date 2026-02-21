import 'package:supabase/supabase.dart';

void main() async {
  final supabase = SupabaseClient(
    'https://poepodtageytnzucrsmg.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBvZXBvZHRhZ2V5dG56dWNyc21nIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEyMjQyNTgsImV4cCI6MjA4NjgwMDI1OH0.V7km9Yd3_sHLUMnpJq4qh03Soj0SfS0LUblKatjhgnM',
  );

  final defaults = [
    {
      'name': 'Technology',
      'icon_code_point': 0xe1b0,
      'color_value': 0xFF3F51B5,
      'sort_order': 0,
    },
    {
      'name': 'Education',
      'icon_code_point': 0xe55c,
      'color_value': 0xFF4CAF50,
      'sort_order': 1,
    },
    {
      'name': 'Software',
      'icon_code_point': 0xe165,
      'color_value': 0xFFF44336,
      'sort_order': 2,
    },
    {
      'name': 'Design',
      'icon_code_point': 0xe11e,
      'color_value': 0xFFE91E63,
      'sort_order': 3,
    },
    {
      'name': 'Business',
      'icon_code_point': 0xe0b9,
      'color_value': 0xFFFF9800,
      'sort_order': 4,
    },
  ];

  try {
    for (final cat in defaults) {
      final signedColor = (cat['color_value'] as int).toSigned(32);
      final insertData = {
        'name': cat['name'],
        'icon_code_point': cat['icon_code_point'],
        'color_value': signedColor,
        'sort_order': cat['sort_order'],
      };

      final res = await supabase.from('categories').insert(insertData).select();
      print('Added: ${res[0]["name"]}');
    }
  } on PostgrestException catch (e) {
    print('Database Error: ${e.message}');
  } catch (e) {
    print('Error: $e');
  }
}
