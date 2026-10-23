import 'package:flutter/material.dart';

class IconMapper {
  static const _map = <String, IconData>{
    'content_cut':              Icons.content_cut_rounded,
    'air':                      Icons.air_rounded,
    'palette':                  Icons.palette_outlined,
    'format_paint':             Icons.format_paint_rounded,
    'brush':                    Icons.brush_outlined,
    'spa':                      Icons.spa_rounded,
    'face':                     Icons.face_rounded,
    'face_retouching_natural':  Icons.face_retouching_natural_outlined,
    'auto_awesome':             Icons.auto_awesome_rounded,
    'visibility':               Icons.visibility_rounded,
    'waves':                    Icons.waves_rounded,
    'loop':                     Icons.loop_rounded,
    'star':                     Icons.star_rounded,
    'remove_circle_outline':    Icons.remove_circle_outline_rounded,
    'science':                  Icons.science_rounded,
    'color_lens':               Icons.color_lens_rounded,
    'arrow_upward':             Icons.arrow_upward_rounded,
    'straighten':               Icons.straighten_rounded,
    'self_improvement':         Icons.self_improvement_rounded,
    'accessibility':            Icons.accessibility_rounded,
    'favorite':                 Icons.favorite_rounded,
    'nights_stay':              Icons.nights_stay_rounded,
    'eco':                      Icons.eco_rounded,
    'style':                    Icons.style_rounded,
    'fitness_center':           Icons.fitness_center_rounded,
    'local_fire_department':    Icons.local_fire_department_rounded,
    'bubble_chart':             Icons.bubble_chart_rounded,
    'wrap_text':                Icons.wrap_text_rounded,
    'wb_sunny':                 Icons.wb_sunny_rounded,
    'miscellaneous_services':   Icons.miscellaneous_services_rounded,
  };

  static IconData fromString(String name) =>
      _map[name] ?? Icons.miscellaneous_services_rounded;
}

/// Convenience top-level function used throughout the UI.
IconData iconFromName(String name) => IconMapper.fromString(name);
