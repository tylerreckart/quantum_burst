import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioPlayer song;
FFT fft;

int stringCount = 50;
WigglingString[] strings = new WigglingString[stringCount];
WigglingString[] whiteStrings = new WigglingString[stringCount];

float hueOffset = 0;
float backgroundHue = 0;

boolean paused = true; // Start paused
boolean recording = false;

void setup() {
  size(1440, 1080);
  smooth(8);
  frameRate(24);
  surface.setResizable(false);

  minim = new Minim(this);
  song = minim.loadFile("strangertings_reverbized.mp3", 1024);
  
  fft = new FFT(song.bufferSize(), song.sampleRate());

  for (int i = 0; i < stringCount; i++) {
    strings[i] = new WigglingString(width/2, height/2, fft, width, height, false);
    whiteStrings[i] = new WigglingString(width/2, height/2, fft, width, height, true);
  }
  
  colorMode(HSB, 360, 100, 100);
  strokeCap(ROUND);
  strokeJoin(ROUND);
}

void draw() {
  background(0, 0, 0);
  
  fft.forward(song.mix);
  
  if (!paused) {
    for (WigglingString ws : strings) {
      ws.update();
    }
    for (WigglingString ws : whiteStrings) {
      ws.update();
    }
  }
  
  for (WigglingString ws : strings) {
    ws.display(hueOffset);
  }

  for (WigglingString ws : whiteStrings) {
    ws.display(hueOffset);
  }
  
  if (recording) {
    saveFrame("output/frame-####.png");
  }
}

void keyPressed() {
  if (keyCode == UP) {
    hueOffset = random(360);
    backgroundHue = random(360);
  } else if (keyCode == LEFT) {
    // Pause animation and audio
    paused = true;
    if (song.isPlaying()) {
      song.pause();
    }
  } else if (keyCode == RIGHT) {
    // Resume animation and restart audio
    paused = false;
    song.rewind();
    song.play();
  } else if (keyCode == DOWN) {
    // Toggle frame recording
    recording = !recording;
  }
}

class WigglingString {
  float cx, cy;         
  float angle;          
  int band;             
  
  float lineLength = 100;   
  float lineLenProgress = 0; 
  float lineGrowSpeed = 2;  
  
  float initialRadius;   
  float radiusOffset = 0;   
  
  float speed = 3;       
  float wiggleAmplitude = 5;   
  float wiggleFrequency = 0.05; 
  
  int minSegments = 50;    
  int maxSegments = 300;   
  
  float maxRadius;      
  FFT fft;
  
  int startDelay;      
  boolean started = false; 
  boolean fullyGrown = false; 
  
  float amplitudeFactor; 
  boolean isWhite; 
  
  float phaseOffset; 
  float freqMult;

  WigglingString(float cx, float cy, FFT fft, float w, float h, boolean isWhite) {
    this.cx = cx;
    this.cy = cy;
    this.fft = fft;
    this.isWhite = isWhite;
    
    float diag = sqrt(w*w + h*h);
    maxRadius = diag; 
    startDelay = int(random(0, 180));
    reset();
  }
  
  void reset() {
    angle = random(TWO_PI);
    band = int(random(5, fft.specSize()/4)); 
    lineLenProgress = 0;
    fullyGrown = false;
    started = false;
    startDelay = int(random(0, 180));
    initialRadius = random(0, 500);
    radiusOffset = 0;  
    amplitudeFactor = random(0.5, 1.0);

    phaseOffset = random(TWO_PI);
    freqMult = random(5, 15);
  }
  
  void update() {
    if (!started) {
      if (frameCount >= startDelay) {
        started = true;
      } else {
        return;
      }
    }
    
    if (!fullyGrown) {
      lineLenProgress += lineGrowSpeed;
      if (lineLenProgress >= lineLength) {
        lineLenProgress = lineLength;
        fullyGrown = true;
      }
    }
    
    radiusOffset += speed;
    if (initialRadius + radiusOffset > maxRadius) {
      reset();
    }
  }
  
  void display(float hueOffset) {
    if (!started) return;
    
    float amp = fft.getBand(band) * 2.0 * amplitudeFactor;  
    float lengthRatio = lineLenProgress / lineLength;
    float currentWiggle = wiggleAmplitude * amp * lengthRatio;
    
    float startDist = initialRadius + radiusOffset;
    float endDist = startDist + lineLenProgress;
    int currentSegments = (int)map(lineLenProgress, 0, lineLength, minSegments, maxSegments);
    
    float baseHue = map(band, 0, fft.specSize(), 0, 360);
    float hueVal = (baseHue + hueOffset) % 360;
    
    float lineHue = isWhite ? 0 : hueVal;
    float lineSat = isWhite ? 0 : 80;
    float lineBri = 100;
    
    noStroke();
    fill(lineHue, lineSat, lineBri);
    
    float blobSize = 24; // size of each blob
    for (int i = 0; i <= currentSegments; i++) {
      float t = float(i) / currentSegments;
      float dist = lerp(startDist, endDist, t);
      
      float dx = cos(angle);
      float dy = sin(angle);
      float px = -dy;
      float py = dx;
      
      float time = frameCount * wiggleFrequency;
      float w = sin((time + t * freqMult) + phaseOffset) * currentWiggle;
      
      float x = cx + dx * dist + px * w;
      float y = cy + dy * dist + py * w;
      
      ellipse(x, y, blobSize, blobSize);
    }
  }
}
