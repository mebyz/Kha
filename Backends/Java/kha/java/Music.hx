package kha.java;

import java.lang.Runnable;

@:classContents('
	java.io.File file;
	javax.sound.sampled.AudioInputStream in;
	javax.sound.sampled.SourceDataLine line;
	int frameSize;
	byte[] buffer = new byte [32 * 1024]; // 32k is arbitrary
	Thread playThread;
	boolean playing;
	boolean notYetEOF;
')
class Music extends kha.Music implements Runnable {
	public function new(filename: String) {
		super();
		init(filename);
	}
	
	@:functionBody('
		try {
			//instance = this;
			java.io.File f = new java.io.File(filename);
			file = f;
			in = javax.sound.sampled.AudioSystem.getAudioInputStream (f);
			javax.sound.sampled.AudioFormat format = in.getFormat();
			javax.sound.sampled.AudioFormat.Encoding formatEncoding = format.getEncoding();
			if (! (formatEncoding.equals (javax.sound.sampled.AudioFormat.Encoding.PCM_SIGNED) ||
				   formatEncoding.equals (javax.sound.sampled.AudioFormat.Encoding.PCM_UNSIGNED))) 
			   throw new javax.sound.sampled.UnsupportedAudioFileException (
								  file.getName() + " is not PCM audio");
		   //System.out.println ("got PCM format");        
		   frameSize = format.getFrameSize(); 
		   javax.sound.sampled.DataLine.Info info =
			   new javax.sound.sampled.DataLine.Info (javax.sound.sampled.SourceDataLine.class, format); 
		   //System.out.println ("got info"); 
		   line = (javax.sound.sampled.SourceDataLine) javax.sound.sampled.AudioSystem.getLine (info); 
		   //System.out.println ("got line");        
		   line.open(); 
		   //System.out.println ("opened line"); 
		   playThread = new Thread (this); 
		   playing = false; 
		   notYetEOF = true;        
		   playThread.start();
		}
		catch (Exception ex) {
			ex.printStackTrace();
		}
	')
	function init(filename : String) : Void {
		
	}
	
	@:functionBody('
		int readPoint = 0;
		int bytesRead = 0;

		try {
			for (;;) {
				while (notYetEOF) {
					if (playing) {
					bytesRead = in.read (buffer, 
								 readPoint, 
								 buffer.length - readPoint);
	                   if (bytesRead == -1) { 
					notYetEOF = false; 
					break;
					}
					// how many frames did we get,
					// and how many are left over?
					//int frames = bytesRead / frameSize;
					int leftover = bytesRead % frameSize;
					// send to line
					line.write (buffer, readPoint, bytesRead-leftover);
					// save the leftover bytes
					System.arraycopy (buffer, bytesRead,
							  buffer, 0, 
							  leftover); 
	                    readPoint = leftover;
					} else { 
					// if not playing                   
					// Thread.yield(); 
					try { Thread.sleep (10);} 
					catch (InterruptedException ie) {}
					}
				} // while notYetEOF
				//System.out.println ("reached eof");
				try {
					in = javax.sound.sampled.AudioSystem.getAudioInputStream (file);
				} catch (javax.sound.sampled.UnsupportedAudioFileException e) {
					e.printStackTrace();
				}
				notYetEOF = true;
			}
			//line.drain();
			//line.stop();
		} catch (java.io.IOException ioe) {
			ioe.printStackTrace();
		} finally {
			// line.close();
		}
	')
	public function run() : Void {
		
	}
	
	@:functionBody('
		playing = true;
		if (!playThread.isAlive())
			playThread.start();
		line.start();
	')
	public function play() : Void {
		
	}
	
	@:functionBody('
		playing = false;
		line.stop();
	')
	public function stop() : Void {
		
	}
}