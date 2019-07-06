PImage img; //<>//
PGraphics pg;
StringList properties = new StringList("red", "green", "blue", "hue", "saturation", "brightness");

int colorDiff = 50;
boolean reverse = true;

// Image to work on (should be in the sketch's data folder
String imageName = "boats.jpg";

void setup() {
  // Need to put height and width here (in that order) manually because Processing
  size(2736, 3648, P2D); // Height, width

  img = loadImage(imageName);
  img.loadPixels();
  
  pg = createGraphics(img.width, img.height, P2D);

  // Posterize as needed
  img.filter(POSTERIZE, 16);

  img.loadPixels();
  for (int i = 0; i < 3; i++) {
    properties.shuffle();
    String property = properties.get(1);
    int xOffset = int(random(img.width));
    int yOffset = int(random(img.height));
    println("Shifting: " + property + " (" + xOffset + ", " + yOffset + ")");
    img = shiftStuff(img, property, xOffset, yOffset);
  }
  img.updatePixels();

  pg.beginDraw();
  pg.image(img, 0, 0);
  pg.endDraw();
  pg.save("shifted_" + imageName);

  // Scripted shifting
  /*
  img.loadPixels();
  img = shiftStuff(img, "red", 100, 200);
  img = shiftStuff(img, "green", -120, -260);
  img = shiftStuff(img, "saturation", 1200, 600);
  */

  // Pixelsort
  print("Finding vectors ... ");
  ArrayList<int[]> v = findVectors(img);
  println(v.size() + " found");

  print("Sorting vectors ... ");
  for (int i = 0; i < v.size(); i++) {
    img = sortVector(img, v.get(i), reverse);
  }
  println("done");

  img.updatePixels();

  pg.beginDraw();
  pg.image(img, 0, 0);
  pg.endDraw();
  image(pg, 0, 0, width, height);
  pg.save("sorted_" + imageName);
}

void draw() {
}

// Shift blues
PImage shiftStuff(PImage img, String property, int xOffset, int yOffset) {
  int[] dupe = new int[img.pixels.length];
  for (int i = 0; i < img.pixels.length; i++) {
    int sourceRow = i / img.width;
    int sourceCol = i % img.width;
    int targetRow;
    if (sourceRow + yOffset < 0) {
      targetRow = img.height + (sourceRow + yOffset);
    } else if (sourceRow + yOffset >= img.height) {
      targetRow = (sourceRow + yOffset) % img.height;
    } else {
      targetRow = sourceRow + yOffset;
    }
    int targetCol = (i + xOffset < 0) ? (i + xOffset + img.width) % img.width : (i + xOffset) % img.width;

    color sourceColor = color(img.pixels[(sourceRow * img.width)+sourceCol]);
    color targetColor = color(img.pixels[(targetRow * img.width)+targetCol]);

    switch (property) {
    case "red":
      colorMode(RGB);
      dupe[(targetRow * img.width)+targetCol] = color(red(sourceColor), green(targetColor), blue(targetColor));
      break;
    case "green":
      colorMode(RGB);
      dupe[(targetRow * img.width)+targetCol] = color(red(targetColor), green(sourceColor), blue(targetColor));
      break;
    case "blue":
      colorMode(RGB);
      dupe[(targetRow * img.width)+targetCol] = color(red(targetColor), green(targetColor), blue(sourceColor));
      break;
    case "hue":
      colorMode(HSB);
      dupe[(targetRow * img.width)+targetCol] = color(hue(sourceColor), saturation(targetColor), brightness(targetColor));
      break;
    case "saturation":
      colorMode(HSB);
      dupe[(targetRow * img.width)+targetCol] = color(hue(targetColor), saturation(sourceColor), brightness(targetColor));
      break;
    case "brightness":
      colorMode(HSB);
      dupe[(targetRow * img.width)+targetCol] = color(hue(targetColor), saturation(targetColor), brightness(sourceColor));
      break;
    }
  }
  arrayCopy(dupe, 0, img.pixels, 0, dupe.length);

  return img;
}

PImage sortVector(PImage img, int[] vector, boolean reverse) { //<>//
  int len = (vector[1] - vector[0]) + 1; //<>//
  int startPoint = vector[0];
  int[] part = sort(subset(img.pixels, startPoint, len));
  
  if (reverse) {
    part = reverse(part);
  }

  arrayCopy(part, 0, img.pixels, startPoint, part.length);

  return img; //<>//
}

ArrayList<int[]> findVectors(PImage img) {
  ArrayList<int[]> vectors = new ArrayList<int[]>();
  int start = 0;
  boolean recording = false;

  for (int i = 0; i < img.pixels.length; i++) {
    if (i > 0) {
      float diff = pxlDiff(img.pixels[i], img.pixels[i-1]);
      
      if (!recording) {
        start = i-1;
        recording = true;
      } else if ((recording && (diff > colorDiff)) || i+1 == img.pixels.length) {
        int[] pair = { start, i-1 };
        vectors.add(pair);
        recording = false;
      }
    }
  }
  return vectors;
}

float pxlDiff(color c1, color c2) {
  float hdiff = abs(hue(c1) - hue(c2));
  float sdiff = abs(saturation(c1) - saturation(c2));
  float bdiff = abs(brightness(c1) - brightness(c2));
  
  return hdiff * (1 + sdiff / 10) * (1 + bdiff / 5);
}