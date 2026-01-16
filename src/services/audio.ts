class AudioService {
  private ctx: AudioContext | null = null;
  private soundEnabled = true;

  constructor() {
    try {
      this.ctx = new (window.AudioContext || (window as any).webkitAudioContext)();
    } catch (e) {
      console.warn("AudioContext not supported");
      this.soundEnabled = false;
    }
  }

  private init() {
    if (!this.ctx) return;
    if (this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  // --- Synthesized SFX ---

  playClick(type: 'light' | 'heavy' = 'light') {
    if (!this.soundEnabled || !this.ctx) return;
    this.init();
    
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    
    osc.connect(gain);
    gain.connect(this.ctx.destination);
    
    if (type === 'light') {
      // High pitch metallic tick
      osc.type = 'square';
      osc.frequency.setValueAtTime(800, this.ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(1200, this.ctx.currentTime + 0.05);
      
      gain.gain.setValueAtTime(0.05, this.ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + 0.05);
      
      osc.start();
      osc.stop(this.ctx.currentTime + 0.05);
    } else {
      // Heavy mechanical thud
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(100, this.ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(50, this.ctx.currentTime + 0.1);
      
      gain.gain.setValueAtTime(0.2, this.ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, this.ctx.currentTime + 0.15);
      
      osc.start();
      osc.stop(this.ctx.currentTime + 0.15);
    }
  }

  playCompletion(tier: 'junk' | 'common' | 'uncommon' | 'rare' | 'epic' | 'mythic' | 'unique' = 'common') {
    if (!this.soundEnabled || !this.ctx) return;
    this.init();

    const t = this.ctx.currentTime;
    
    if (tier === 'common') {
      this.playTone(600, 'sine', 0.1, t);
    } else if (tier === 'rare') {
      // Major Chord Arpeggio
      this.playTone(523.25, 'sine', 0.3, t); // C5
      this.playTone(659.25, 'sine', 0.3, t + 0.1); // E5
      this.playTone(783.99, 'sine', 0.5, t + 0.2); // G5
    } else if (tier === 'mythic') {
       // Ethereal sweep
       const osc = this.ctx.createOscillator();
       const gain = this.ctx.createGain();
       osc.connect(gain);
       gain.connect(this.ctx.destination);
       
       osc.type = 'sine';
       osc.frequency.setValueAtTime(200, t);
       osc.frequency.linearRampToValueAtTime(800, t + 2);
       
       gain.gain.setValueAtTime(0, t);
       gain.gain.linearRampToValueAtTime(0.2, t + 1);
       gain.gain.linearRampToValueAtTime(0, t + 3);
       
       osc.start(t);
       osc.stop(t + 3);
    }
  }

  private playTone(freq: number, type: OscillatorType, duration: number, startTime: number) {
    if (!this.ctx) return;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    
    osc.connect(gain);
    gain.connect(this.ctx.destination);
    
    osc.type = type;
    osc.frequency.value = freq;
    
    gain.gain.setValueAtTime(0.1, startTime);
    gain.gain.exponentialRampToValueAtTime(0.001, startTime + duration);
    
    osc.start(startTime);
    osc.stop(startTime + duration);
  }

  // --- Ambience ---
  // (Simplified noise generator)
  startAmbience() {
     // Ideally loading a loop, but we can try pink noise buffer
     if (!this.soundEnabled || !this.ctx) return;
     // Noise generation is heavy, maybe skip for now or use a simple loop if files existed.
  }
}

export const audio = new AudioService();
