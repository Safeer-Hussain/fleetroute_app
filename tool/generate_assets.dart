import 'dart:io';
import 'dart:math';

void main() {
  Directory('assets/icons').createSync(recursive: true);
  Directory('assets/images').createSync(recursive: true);

  // 1. App Icon: 512x512 obsidian background, emerald-amber route vector & telemetry node
  generatePng(
    path: 'assets/icons/app_icon.png',
    width: 512,
    height: 512,
    painter: (x, y, w, h) {
      // Background: Obsidian logistics dark #0F172A
      final cx = w / 2;
      final cy = h / 2;
      final dist = sqrt((x - cx) * (x - cx) + (y - cy) * (y - cy));

      // Outer squircle or rounded container
      final dx = (x - cx).abs();
      final dy = (y - cy).abs();
      if (dx > 230 || dy > 230) {
        return [15, 23, 42, 0]; // transparent outside icon frame
      }
      if (dx > 210 &&
          dy > 210 &&
          sqrt(pow(dx - 210, 2) + pow(dy - 210, 2)) > 20) {
        return [15, 23, 42, 0];
      }

      // Orbital Route Vector (Emerald #10B981 ring with Amber #F59E0B node)
      final ringDist = (dist - 140).abs();
      if (ringDist < 14) {
        // Emerald route ring
        return [16, 185, 129, 255];
      }

      // Angular cargo arrow / node vector
      final angle = atan2(y - cy, x - cx);
      if (dist > 70 && dist < 170 && (angle > -0.7 && angle < 0.2)) {
        // Amber pulse trail
        return [245, 158, 11, 240];
      }

      // Central core telematics node
      if (dist < 55) {
        return [14, 165, 233, 255]; // Sky cyan core
      }
      if (dist < 65) {
        return [255, 255, 255, 200]; // Halo
      }

      // Subtle tech grid pattern
      if ((x % 32 == 0 || y % 32 == 0) && dist < 200) {
        return [30, 41, 59, 255];
      }

      return [15, 23, 42, 255]; // Obsidian background
    },
  );

  // 2. Heavy Semi-Truck
  generatePng(
    path: 'assets/images/heavy_semi_truck.png',
    width: 512,
    height: 320,
    painter: (x, y, w, h) {
      // Background gradient dark slate
      if (y > 270) return [15, 23, 42, 255];
      // Road line
      if (y >= 264 && y <= 270) return [100, 116, 139, 255];
      // Semi truck silhouette
      // Trailer: x from 60 to 320, y from 90 to 240
      if (x >= 60 && x <= 320 && y >= 90 && y <= 240) {
        if (x > 80 && x < 300 && (y == 130 || y == 190)) {
          return [56, 189, 248, 255]; // Blue metallic logistics stripes
        }
        return [30, 58, 138, 255]; // Deep enterprise navy
      }
      // Cab: x from 325 to 440, y from 120 to 240
      if (x >= 325 && x <= 440 && y >= 120 && y <= 240) {
        // Windshield
        if (x >= 370 && x <= 430 && y >= 130 && y <= 170) {
          return [186, 230, 253, 255]; // Glass
        }
        return [16, 185, 129, 255]; // Emerald cab
      }
      // Wheels
      for (final wx in [100, 150, 270, 310, 400]) {
        final wdist = sqrt(pow(x - wx, 2) + pow(y - 250, 2));
        if (wdist <= 22) {
          if (wdist <= 8) return [203, 213, 225, 255]; // Hub
          return [15, 23, 42, 255]; // Tire
        }
      }
      return [15, 23, 42, 255];
    },
  );

  // 3. Refrigerated Cold-Chain Van
  generatePng(
    path: 'assets/images/cold_chain_van.png',
    width: 512,
    height: 320,
    painter: (x, y, w, h) {
      if (y >= 264 && y <= 270) return [100, 116, 139, 255];
      // Cold-chain unit on roof: x from 120 to 240, y from 85 to 110
      if (x >= 120 && x <= 240 && y >= 85 && y <= 110) {
        return [14, 165, 233, 255]; // Cyan reefer unit
      }
      // Box body: x from 100 to 360, y from 110 to 240
      if (x >= 100 && x <= 360 && y >= 110 && y <= 240) {
        // Snowflake/frost stripe
        if (y >= 165 && y <= 185) return [56, 189, 248, 255];
        return [241, 245, 249, 255]; // Insulated white body
      }
      // Van cab: x from 360 to 440, y from 140 to 240
      if (x >= 360 && x <= 440 && y >= 140 && y <= 240) {
        if (x >= 380 && x <= 430 && y >= 145 && y <= 180) {
          return [186, 230, 253, 255]; // Windshield
        }
        return [14, 165, 233, 255]; // Cyan cab
      }
      // Wheels
      for (final wx in [150, 400]) {
        final wdist = sqrt(pow(x - wx, 2) + pow(y - 250, 2));
        if (wdist <= 22) {
          if (wdist <= 8) return [203, 213, 225, 255];
          return [15, 23, 42, 255];
        }
      }
      return [15, 23, 42, 255];
    },
  );

  // 4. Electric Express Courier
  generatePng(
    path: 'assets/images/electric_courier.png',
    width: 512,
    height: 320,
    painter: (x, y, w, h) {
      if (y >= 264 && y <= 270) return [100, 116, 139, 255];
      // Sleek EV aerodynamic body: x from 110 to 420, y from 130 to 240
      if (x >= 110 && x <= 420 && y >= 130 && y <= 240) {
        // Battery glow bar on chassis
        if (y >= 225 && y <= 235) {
          return [16, 185, 129, 255]; // Green EV battery glow
        }
        // EV windshield
        if (x >= 340 && x <= 410 && y >= 135 && y <= 175) {
          return [224, 242, 254, 255];
        }
        return [30, 41, 59, 255]; // Slate aerodynamic body
      }
      // Wheels
      for (final wx in [160, 380]) {
        final wdist = sqrt(pow(x - wx, 2) + pow(y - 250, 2));
        if (wdist <= 20) {
          if (wdist <= 7) return [16, 185, 129, 255]; // Emerald rim
          return [15, 23, 42, 255];
        }
      }
      return [15, 23, 42, 255];
    },
  );

  // 5. Driver Avatar
  generatePng(
    path: 'assets/images/driver_avatar.png',
    width: 256,
    height: 256,
    painter: (x, y, w, h) {
      final cx = w / 2;
      final cy = h / 2;
      final dist = sqrt(pow(x - cx, 2) + pow(y - cy, 2));
      if (dist > 120) return [0, 0, 0, 0];
      // Head
      final headDist = sqrt(pow(x - cx, 2) + pow(y - (cy - 25), 2));
      if (headDist <= 45) return [251, 191, 36, 255]; // Amber skin
      // Shoulders
      if (y > cy + 20 && dist <= 110) {
        return [30, 58, 138, 255]; // Logistics uniform navy
      }
      return [30, 41, 59, 255]; // Background circle
    },
  );

  // 6. Depot Geofence Badge
  generatePng(
    path: 'assets/images/depot_geofence.png',
    width: 256,
    height: 256,
    painter: (x, y, w, h) {
      final cx = w / 2;
      final cy = h / 2;
      final dist = sqrt(pow(x - cx, 2) + pow(y - cy, 2));
      if (dist > 120) return [0, 0, 0, 0];
      // Hexagon / circular radar boundary
      if ((dist - 100).abs() <= 6 ||
          (dist - 65).abs() <= 4 ||
          (dist - 30).abs() <= 3) {
        return [16, 185, 129, 255]; // Emerald geofence boundary
      }
      // Crosshairs
      if ((x == cx.toInt() || y == cy.toInt()) && dist <= 100) {
        return [16, 185, 129, 180];
      }
      return [15, 23, 42, 255];
    },
  );

  print('All 6 assets successfully generated.');
}

void generatePng({
  required String path,
  required int width,
  required int height,
  required List<int> Function(int x, int y, int w, int h) painter,
}) {
  final rawData = <int>[];
  for (int y = 0; y < height; y++) {
    rawData.add(0); // Filter byte: 0 = None
    for (int x = 0; x < width; x++) {
      final rgba = painter(x, y, width, height);
      rawData.addAll(rgba);
    }
  }

  final compressed = zlib.encode(rawData);

  final bytes = <int>[
    // PNG signature
    137, 80, 78, 71, 13, 10, 26, 10,
    // IHDR chunk
    ..._makeChunk('IHDR', [
      ..._int32(width),
      ..._int32(height),
      8, // 8 bits per channel
      6, // RGBA
      0, // Deflate compression
      0, // Filter
      0, // Interlace
    ]),
    // IDAT chunk
    ..._makeChunk('IDAT', compressed),
    // IEND chunk
    ..._makeChunk('IEND', []),
  ];

  File(path).writeAsBytesSync(bytes);
}

List<int> _int32(int v) => [
  (v >> 24) & 0xFF,
  (v >> 16) & 0xFF,
  (v >> 8) & 0xFF,
  v & 0xFF,
];

List<int> _makeChunk(String type, List<int> data) {
  final typeBytes = type.codeUnits;
  final length = _int32(data.length);
  final toCrc = <int>[...typeBytes, ...data];
  final crc = _int32(_crc32(toCrc));
  return [...length, ...toCrc, ...crc];
}

int _crc32(List<int> data) {
  var c = 0xFFFFFFFF;
  for (final b in data) {
    c ^= b;
    for (var k = 0; k < 8; k++) {
      c = (c & 1 != 0) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1);
    }
  }
  return c ^ 0xFFFFFFFF;
}
