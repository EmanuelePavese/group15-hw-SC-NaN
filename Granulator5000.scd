
//// START
s.boot;
GUI.current
(
var w, buf1, buf2, buf3, grainBufScopingSynth, grainFMScopingSynth, grainInScopingSynth, fastcutEnv, percEnv, transEnv, dippedEnv, constantEnv, menuEnv1, menuEnv2, menuEnv3, soundFile, soundFile2, soundFile3, num,  channel1, channel2, channel3, boxAtk, boxDcy, boxSst, boxRls, boxAtk2, boxDcy2, boxSst2, boxRls2, boxAtk3, boxDcy3, boxSst3, boxRls3, knobW, knobH, posH1, posV1, posH2, posV2, posH3, posV3, distH, distV;


Window.closeAll;
Buffer.freeAll;

w = Window("Granulator 5000", Rect(10,20,700,700));
w.front;



~cyan = Color.green;
~black = Color.black;
~color1 = Color.fromHexString("09D2EC");
~color2 = Color.fromHexString("EF04C7");
~color3 = Color.fromHexString("77F32B");
~colors1 = [~color1, ~color1, ~black, Color.yellow];
~colors2 = [~color1, ~color2, ~black, Color.yellow];
~colors3 = [~color1, ~color3, ~black, Color.yellow];
w.background = Color.black;

//Custom envelopes for each grain

fastcutEnv = Env.new([0,0.5,1,1,0.5,0],[0.125,0.125,0.5,0.125,0.125],[3,-3,0,3,-3]);
~fastcutSmooth = Buffer.sendCollection(s,fastcutEnv.discretize(2048));

percEnv = Env.new([0,1,0],[0.01,1],[0,-4]);
~percSmooth = Buffer.sendCollection(s,percEnv.discretize(2048));

transEnv = Env.new([1,1,0],[0.5, 0.5]);
~transSmooth = Buffer.sendCollection(s,transEnv.discretize(2048));

dippedEnv = Env.new([0,1,0],[0,1],[-3]);
~dippedSmooth = Buffer.sendCollection(s,dippedEnv.discretize(2048));

constantEnv = Env.new([0,1,0],[0,1],[3]);
~constantpowerSmooth = Buffer.sendCollection(s,constantEnv.discretize(2048));

//This is needed to plot the signals in the GUI

buf1 = Buffer.alloc(s, 1024, 1);
buf2 = Buffer.alloc(s, 1024, 1);
buf3 = Buffer.alloc(s, 1024, 1);

~path= thisProcess.nowExecutingPath.dirname;

~grainBufScope = ScopeView(w, Rect(10,10,300,150)).resize_(5).style_(0).waveColors = [~color1];
~grainFMScope = ScopeView(w, Rect(10,205,300,150)).resize_(5).style_(0).waveColors = [~color2];
~grainInScope = ScopeView(w, Rect(10,410,300,150)).resize_(5).style_(0).waveColors = [~color3];

~grainBufScope.yZoom = 3;
~grainFMScope.yZoom = 3;
~grainInScope.yZoom = 3;



~grainBufScope.bufnum = buf1.bufnum;      // Assegna il Buffer (nel quale c'è il segnale da visualizzare) allo scopeview
~grainFMScope.bufnum = buf2.bufnum;
~grainInScope.bufnum = buf3.bufnum;

~grainBufScope.server_(s);             // Assegna il Server allo scopeview
~grainFMScope.server_(s);
~grainInScope.server_(s);


~grainFMScope.start;    // lo scope è "acceso"
~grainInScope.start;
~grainBufScope.start;


~imagePath = (~path +/+ "./images/GRANULATOR.png");
~pressPath = (~path +/+ "./images/Press.png");

~image = Image.new(~imagePath);
~pressImage = Image.new(~pressPath);
w.drawHook_({
~image.drawInRect(Rect(160,560,500,350), Rect(0,0,820,500), 2, 1.0);
~pressImage.drawInRect(Rect(200,620,300,250), Rect(0,0,1000,500), 2, 1.0);
});


w.onClose_({Buffer.freeAll; t.free; u.free; c.free; ~grainFMScope.free; ~grainInScope.free; ~grainBufScope.free; grainBufScopingSynth.free; grainFMScopingSynth.free; grainInScopingSynth.free});

///DEFINING AND ADDING SYNTHS TO SERVER

//Synth to plot signals in the gui

SynthDef(\scoping, {arg bus, buffy;

	ScopeOut2.ar(In.ar(bus,1), buffy); // Scrive nel Buffer
	Out.ar([0,1], In.ar(bus,1));

}).add;



//First synth: Granular synth to an external signal (audio file)

SynthDef(\GrainBufSample,{

 arg t_gate=1, grainDens=10, grainLength=0.1, lengthRand=1, buff=0,
 playRate=1, grainSmooth=(-1),
 pan=0, panFreq=0.1, panRand=0, amp=0.5, bus, amp0=0.5, amp1=0.5,amp2=0.5, amp3=0.5, amp4=0.5, amp5=0.5, amp6=0.5, amp7=0.5, amp8=0.5, amp9=0.5, atk=0.5, dcy=0.5,sst=1, rls=0.5, wet=0.1, sr=16000;

 var sig, env, densCtrl, lengthCtrl, trig;

 env = EnvGen.kr(
  Env([0,1,0.5,0.5,0],[atk, dcy, sst, rls],\lin),
  t_gate,
 );

 densCtrl = Dust.ar(grainDens);

 lengthCtrl = grainLength*LFNoise1.kr(100).exprange(1/lengthRand, lengthRand);

 sig = GrainBuf.ar(
  2,
  densCtrl,
  lengthCtrl,
  buff,
  playRate,
  envbufnum: grainSmooth, // ~percSmooth, ~transSmooth, ~dippedSmooth, ~fastcutSmooth, ~constantpowerSmooth
 );

 sig = DynKlank.ar(`[[31, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000], [amp0, amp1,amp2, amp3, amp4, amp5, amp6, amp7, amp8, amp9], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]], sig);

	//trig = Impulse.ar(sr);

	sig = Latch.ar(sig,Impulse.ar(sr));

	sig = Normalizer.ar(sig, 1/3);

 sig = sig * env * amp;

 Out.ar(bus,sig);

}).add;


//Second synth: Granular synth to a modulated sinusoid

SynthDef(\GrainFMSample,{

 arg t_gate=1, grainDens=10, grainLength=0.1, lengthRand=1,
 freqCtrl=440, amp=0.5, bus, grainSmooth=(-1), modFreq=0, amp0=0.5, amp1=0.5, amp2=0.5, amp3=0.5, amp4=0.5, amp5=0.5, amp6=0.5, amp7=0.5, amp8=0.5, amp9=0.5, atk=0.5, dcy=0.5, sst=1, rls=0.5;

 var sig, env, densCtrl, lengthCtrl;


 env = EnvGen.kr(
  Env([0,1,0.5,0.5,0],[atk, dcy, sst, rls],\lin),
  t_gate,
 );

 densCtrl = Dust.ar(grainDens);

 lengthCtrl = grainLength*LFNoise1.kr(100).exprange(1/lengthRand, lengthRand);

 sig = GrainFM.ar(
  2,
  densCtrl,
  lengthCtrl,
  freqCtrl,
  modFreq,
  envbufnum: grainSmooth, // ~percSmooth, ~transSmooth, ~dippedSmooth, ~fastcutSmooth, ~constantpowerSmooth
 );

 sig = DynKlank.ar(`[[31, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000], [amp0, amp1,amp2, amp3, amp4, amp5, amp6, amp7, amp8, amp9], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]], sig);

 sig = Normalizer.ar(sig, 1/3);

 sig = sig * env * amp;

 Out.ar(bus,sig);

}).add;


//Third synth: Granular synth to a noise (or to other signal TBD)

SynthDef(\GrainInSample,{

 arg t_gate=1, grainDens=10, grainLength=0.1, lengthRand=1,
 bus, grainSmooth=(-1), amp=0.5, amp0=0.5, amp1=0.5,amp2=0.5, amp3=0.5, amp4=0.5, amp5=0.5, amp6=0.5, amp7=0.5, amp8=0.5, amp9=0.5, atk=0.5, dcy=0.5, sst=1,rls=0.5, noiseType=0, sr=16000;

 var sig, env, densCtrl, lengthCtrl, inCtrl, nt, trig;

 env = EnvGen.kr(
  Env([0,1,0.5,0.5,0],[atk, dcy, sst, rls],\lin),
  t_gate,
 );

 densCtrl = Dust.ar(grainDens);

 lengthCtrl = grainLength*LFNoise1.kr(100).exprange(1/lengthRand, lengthRand);

 nt = [WhiteNoise.ar, PinkNoise.ar, BrownNoise.ar, ClipNoise.ar, Crackle.ar];
 inCtrl = Select.ar(noiseType, nt);

 sig = GrainIn.ar(
  2,
  densCtrl,
  lengthCtrl,
  inCtrl,
  envbufnum: grainSmooth,
 );

	sig = BLowPass.ar(sig, 1200);

	sig = DynKlank.ar(`[[31, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000], [amp0, amp1,amp2, amp3, amp4, amp5, amp6, amp7, amp8, amp9], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]], sig);

	trig = Impulse.ar(sr);

	sig = Latch.ar(sig,trig);

	sig = Normalizer.ar(sig, 1/3);

	sig = sig * env * amp;

	Out.ar(bus,sig);

}).add;

//{master = Synth(\master)}.defer(0.2);

///SCOPE SYNTH

{grainBufScopingSynth = Synth(\scoping, [\buffy, buf1.bufnum, \bus, 5])}.defer(0.1);
{grainFMScopingSynth = Synth(\scoping, [\buffy, buf2.bufnum, \bus, 8])}.defer(0.1);
{grainInScopingSynth = Synth(\scoping, [\buffy, buf3.bufnum, \bus, 11])}.defer(0.1);


// "channels"
//Each channel has a menu to select the synth to be used
g = EZPopUpMenu(parentView: w,bounds:Rect(10,10,60,22))
.setColors(menuBackground: Color.black, menuStringColor:~color1)
.addItem(\none,{
	t.free;
	channel1=0;
})
.addItem(\Sample,
	{
		channel1 = 1;
		Dialog.openPanel(
			okFunc: { arg path,
				soundFile = SoundFile.new;
				soundFile.openRead(path);
				b = Buffer.readChannel(s, path, channels: [0]);

				{t = Synth.newPaused(\GrainBufSample,[
					\buff, b,
					\bus,5,
				])}.defer(0.2);

				//Plot initialization
				~grainBufScope.start;
			},
			cancelFunc: {"cancelled"}
		);

		//Managing knobs on GUI

		~pitchS1.visible = true;
		~frqS1.visible = false;
		~modS1.visible = false;
		~typeNS1.visible = false;
		~decS1.visible = true;

		~pitchTxt1.string_("Pitch");
		~decTxt1.string_("Sampling");


})
.addItem(\SineFM,
	{
		channel1 = 1;

		{t = Synth.newPaused(\GrainFMSample,[
			\bus,5,
		])}.defer(0.2);
		//Plot initialization
		~grainBufScope.start;

		//Managing knobs on GUI
		~pitchS1.visible = false;
		~frqS1.visible = true;
		~modS1.visible = true;
		~typeNS1.visible = false;
		~decS1.visible = false;

		~pitchTxt1.string_("Freq");
		~decTxt1.string_("Mod");


})
.addItem(\Noise,
	{
		channel1 = 1;

		{t = Synth.newPaused(\GrainInSample,[
			\bus,5,
		])}.defer(0.2);
		~grainBufScope.start;

		//Managing knobs on GUI

		~pitchS1.visible = false;
		~frqS1.visible = false;
		~modS1.visible = false;
		~typeNS1.visible = true;
		~decS1.visible = true;

		~pitchTxt1.string_("Type");
		~decTxt1.string_("Sampling");

});



/// SYNTH 2

h = EZPopUpMenu(parentView: w,bounds:Rect(10,205,60,22))
.setColors(menuBackground: Color.black, menuStringColor:~color2)
.addItem(\none,{
	c.free;
	channel2=0;
})
.addItem(\Sample,
	{
		Dialog.openPanel(
			okFunc: { arg path,
				soundFile2 = SoundFile.new;
				soundFile2.openRead(path);
				e = Buffer.readChannel(s, path, channels: [0]);

				channel2=1;

				{c = Synth.newPaused(\GrainBufSample,[
					\buff, e,
					\bus,8,
				])}.defer(0.2);
				//Plot initialization
				~grainFMScope.start;

			},
			cancelFunc: {"cancelled"}
		);

		~pitchS2.visible = true;
		~frqS2.visible = false;
		~modS2.visible = false;
		~typeNS2.visible = false;
		~decS2.visible = true;

		~pitchTxt2.string_("Pitch");
		~decTxt2.string_("Sampling");
})
.addItem(\SineFM,
	{
		channel2=1;

		{c = Synth.newPaused(\GrainFMSample,[
			\bus,8,
		])}.defer(0.2);
		//Plot initialization
		~grainFMScope.start;

		~pitchS2.visible = false;
		~frqS2.visible = true;
		~modS2.visible = true;
		~typeNS2.visible = false;
		~decS2.visible = false;

		~pitchTxt2.string_("Freq");
		~decTxt2.string_("Mod");

})
.addItem(\Noise,
	{

		channel2=1;

		{c = Synth.newPaused(\GrainInSample,[
			\bus,8,
		])}.defer(0.2);
		//Plot initialization
		~grainFMScope.start;

		~pitchS2.visible = false;
		~frqS2.visible = false;
		~modS2.visible = false;
		~typeNS2.visible = true;
		~decS2.visible = true;

		~pitchTxt2.string_("Type");
		~decTxt2.string_("Sampling");

});


///SYNTH 3

o = EZPopUpMenu(parentView: w,bounds:Rect(10,410,60,22))
.setColors(menuBackground: Color.black, menuStringColor:~color3)
.addItem(\none,{
	u.free;
	channel3=0;
})
.addItem(\Sample,
	{
		Dialog.openPanel(
			okFunc: { arg path,
				soundFile3 = SoundFile.new;
				soundFile3.openRead(path);
				q = Buffer.readChannel(s, path, channels: [0]);

				{u = Synth.newPaused(\GrainBufSample,[
					\buff, q,
					\bus,11,
				])}.defer(0.2);

				//Plot initialization
				~grainInScope.start;

				channel3 = 1;
			},
			cancelFunc: {"cancelled"}
		);

		~pitchS3.visible = true;
		~frqS3.visible = false;
		~modS3.visible = false;
		~typeNS3.visible = false;
		~decS3.visible = true;

		~pitchTxt3.string_("Pitch");
		~decTxt3.string_("Sampling");
})
.addItem(\SineFM,
	{
		channel3 = 1;

		{u = Synth.newPaused(\GrainFMSample,[
			\bus,11,
		])}.defer(0.2);
								//Plot initialization
		~grainInScope.start;

		~pitchS3.visible = false;
		~frqS3.visible = true;
		~modS3.visible = true;
		~typeNS3.visible = false;
		~decS3.visible = false;

		~pitchTxt3.string_("Freq");
		~decTxt3.string_("Mod");

})
.addItem(\Noise,
	{
		channel3 = 1;

		{u = Synth.newPaused(\GrainInSample,[
			\bus,11,
		])}.defer(0.2);
		//Plot initialization
		~grainInScope.start;

		~pitchS3.visible = false;
		~frqS3.visible = false;
		~modS3.visible = false;
		~typeNS3.visible = true;
		~decS3.visible = true;


		~pitchTxt3.string_("Type");
		~decTxt3.string_("Samp");

});



////////////GRAPHICAL ELEMENTS

//KNOBS

/// knobs Channel 1
//First two knobs are common to all synth, the other two change for each synth

posH1 = 320;
posV1 = 5;
distH = 50;
distV = 85;

knobW = 40;
knobH = 80;


~densS1 = Knob(w, Rect(posH1,posV1,knobW,knobH))
.color_(~colors1)
.mode_(\vert)
.value_(10.linlin(1,350,0,1))
.background_(Color.black)
.action_({
	arg obj;
	var cf;
	cf = obj.value.postln;
	t.set(\grainDens,obj.value.linlin(0,1,1,350).postln);
});


~sizeS1 = Knob(w, Rect(posH1+distH,posV1,knobW,knobH))
.color_(~colors1)
.mode_(\vert)
.value_(0.1.linlin(0.001,1,0,1))
.background_(~black)
.action_({
	arg obj;
	var cf;
	cf = obj.value.postln;
	t.set(\grainLength,obj.value.linlin(0,1,0.001,1).postln);
});


//For GrainBuf

~pitchS1 = Knob(w, Rect(posH1,posV1+distV,knobW,knobH))
.color_(~colors1)
.mode_(\vert)
.value_(1.linlin(0,2,0,1))
.background_(~black)
.action_({
	arg obj;
	var cf;
	cf = obj.value.postln;
	t.set(\playRate, obj.value.linlin(0,1,0,2).postln);
});

~decS1 = Knob(w, Rect(posH1+distH,posV1+distV,knobW,knobH))
.color_(~colors1)
.mode_(\vert)
.value_(16000.linlin(256,16000,0,1))
.background_(Color.black)
.action_({
	arg obj;
	var cf;
	cf = obj.value.postln;
 t.set(\sr,obj.value.linlin(0,1,256,16000).postln);
});


///for Sine FM

~frqS1 = Knob(w, Rect(posH1,posV1+distV,knobW,knobH))
.color_(~colors1)
.mode_(\vert)
.value_(460.linlin(80,1000,0,1)).postln
.background_(Color.black)
.action_({
	arg obj;
	var cf;
	cf = obj.value.postln;
	t.set(\freqCtrl,obj.value.linlin(0,1,80,1000).postln);
});

~modS1 = Knob(w, Rect(posH1+distH,posV1+distV,knobW,knobH))
.color_(~colors1)
.mode_(\vert)
.value_(0.linlin(0,20,0,1))
.background_(Color.black)
.action_({
	arg obj;
	var cf;
	cf = obj.value.postln;
	t.set(\modFreq,obj.value.linlin(0,1,0,20).postln);
});


//For Noise

~typeNS1 = Knob(w, Rect(posH1,posV1+distV,knobW,knobH))
.step_(1/4)
.color_(~colors1)
.mode_(\vert)
.value_(0.linlin(0,4,0,1))
.background_(Color.black)
.action_({
	arg obj;
	var cf;
	cf = obj.value.postln;
	t.set(\noiseType,obj.value.linlin(0,1,0,5).postln);
});


/// knobs synth2

posH2 = 320;
posV2 = 200;

~densS2 = Knob(w, Rect(posH2,posV2,knobW,knobH))
.color_(~colors2)
.mode_(\vert)
.value_(10.linlin(1,350,0,1)).postln
.background_(~black)
.action_({
	arg obj;
	var cf;
	cf = obj.value;
	c.set(\grainDens,obj.value.linlin(0,1,1,350).postln);
});


~sizeS2 = Knob(w, Rect(posH2+distH,posV2,knobW,knobH))
.color_(~colors2)
.mode_(\vert)
.value_(0.1.linlin(0.001,1,0,1))
.background_(~black)
.action_({
	arg obj;
	var cf;
	cf = obj.value;
	c.set(\grainLength,obj.value.linlin(0,1,0.001,1));
});


//For GrainBuf

~pitchS2 = Knob(w, Rect(posH2,posV2+distV,knobW,knobH))
.color_(~colors2)
.mode_(\vert)
.value_(1.linlin(0,2,0,1))
.background_(~black)
.action_({
	arg obj;
	var cf;
	cf = obj.value;
	c.set(\playRate,obj.value.linlin(0,1,0,2));
});

~decS2 = Knob(w, Rect(posH2+distH,posV2+distV,knobW,knobH))
.color_(~colors2)
.mode_(\vert)
.value_(16000.linlin(256,16000,0,1))
.background_(Color.black)
.action_({
 arg obj;
 c.set(\sr,obj.value.linlin(0,1,256,16000));
});


//For SineFM

~frqS2 = Knob(w, Rect(posH2,posV2+distV,knobW,knobH))
.color_(~colors2)
.mode_(\vert)
.value_(440.linlin(80,1000,0,1))
.background_(Color.black)
.action_({
	arg obj;
	var cf;
	cf = obj.value;
	c.set(\freqCtrl,obj.value.linlin(0,1,80,1000));
});

~modS2 = Knob(w, Rect(posH2+distH,posV2+distV,knobW,knobH))
.color_(~colors2)
.mode_(\vert)
.value_(0.linlin(0,20,0,1))
.background_(Color.black)
.action_({
	arg obj;
	var cf;
	cf = obj.value;
	c.set(\modFreq,obj.value.linlin(0,1,0,20));
});


//For Noise

~typeNS2 = Knob(w, Rect(posH2,posV2+distV,knobW,knobH))
.step_(1/4)
.color_(~colors2)
.mode_(\vert)
.value_(0.linlin(0,4,0,1))
.background_(Color.black)
.action_({
	arg obj;
	var cf;
	cf = obj.value;
	c.set(\noiseType,obj.value.linlin(0,1,0,5));
});


// knobs synth3

posH3=320;
posV3=370;

~densS3 = Knob(w, Rect(posH3,posV3,knobW,knobH))
.color_(~colors3)
.mode_(\vert)
.value_(10.linlin(1,350,0,1))
.background_(~black)
.action_({
	arg obj;
	var cf;
	cf = obj.value;
	u.set(\grainDens,obj.value.linlin(0,1,1,350));
});


~sizeS3 = Knob(w, Rect(posH3+distH,posV3,knobW,knobH))
.color_(~colors3)
.mode_(\vert)
.value_(0.1.linlin(0.001,1,0,1))
.background_(~black)
.action_({
	arg obj;
	var cf;
	cf = obj.value;
	u.set(\grainLength,obj.value.linlin(0,1,0.001,1));
});


//For GrainBuf

~pitchS3 = Knob(w, Rect(posH3,posV3+distV,knobW,knobH))
.color_(~colors3)
.mode_(\vert)
.value_(1.linlin(0,2,0,1))
.background_(~black)
.action_({
	arg obj;
	var cf;
	cf = obj.value;
	u.set(\playRate,obj.value.linlin(0,1,0,2));
});

~decS3 = Knob(w, Rect(posH3+distH,posV3+distV,knobW,knobH))
.color_(~colors3)
.mode_(\vert)
.value_(16000.linlin(256,16000,0,1))
.background_(Color.black)
.action_({
 arg obj;
 u.set(\sr,obj.value.linlin(0,1,256,16000));
});


//For SineFM

~frqS3 = Knob(w, Rect(posH3,posV3+distV,knobW,knobH))
.color_(~colors3)
.mode_(\vert)
.value_(440.linlin(80,1000,0,1))
.background_(Color.black)
.action_({
	arg obj;
	var cf;
	cf = obj.value;
	u.set(\freqCtrl, obj.value.linlin(0,1,80,1000));
});

~modS3 = Knob(w, Rect(posH3+distH,posV3+distV,knobW,knobH))
.color_(~colors3)
.mode_(\vert)
.value_(0.linlin(0,20,0,1))
.background_(Color.black)
.action_({
	arg obj;
	var cf;
	cf = obj.value;
	u.set(\modFreq, obj.value.linlin(0,1,0,20));
});


//For Noise

~typeNS3 = Knob(w, Rect(posH3,posV3+distV,knobW,knobH))
.step_(1/4)
.color_(~colors3)
.mode_(\vert)
.value_(0.linlin(0,4,0,1))
.background_(Color.black)
.action_({
	arg obj;
	var cf;
	cf = obj.value;
	u.set(\noiseType, obj.value.linlin(0,1,0,4).postln);
});


//Managing knobs on start, by default synth 1 (sample) knobs are shown

~pitchS1.visible = true;
~decS1.visible = true;
~frqS1.visible = false;
~modS1.visible = false;
~typeNS1.visible = false;



~pitchS2.visible = true;
~decS2.visible = true;
~frqS2.visible = false;
~modS2.visible = false;
~typeNS2.visible = false;


~pitchS3.visible = true;
~decS3.visible = true;
~frqS3.visible = false;
~modS3.visible = false;
~typeNS3.visible = false;



///MENU GRAIN ENVELOPES
//Assigning individual grain envelopes to synth on channel 1 (it's the menu on the right)

menuEnv1 = EZPopUpMenu(parentView: w,bounds:Rect(420,8,60,22))
.setColors(menuBackground: ~black, menuStringColor: ~color1)
.addItem(\Hann,{
	t.set(\grainSmooth,-1);
})
.addItem(\fastCut,{
	t.set(\grainSmooth,~fastcutSmooth);
})
.addItem(\perc,{
	t.set(\grainSmooth,~percSmooth);
})
.addItem(\trans,{
	t.set(\grainSmooth,~transSmooth);
})
.addItem(\dipped,{
	t.set(\grainSmooth,~dippedSmooth);
})
.addItem(\constant,{
	t.set(\grainSmooth,~constantpowerSmooth);
});

menuEnv2 = EZPopUpMenu(parentView: w,bounds:Rect(420,200,60,22))
.setColors(menuBackground: ~black, menuStringColor: ~color2)
.addItem(\Hann,{
	c.set(\grainSmooth,-1);
})
.addItem(\fastCut,{
	c.set(\grainSmooth,~fastcutSmooth);
})
.addItem(\perc,{
	c.set(\grainSmooth,~percSmooth);
})
.addItem(\trans,{
	c.set(\grainSmooth,~transSmooth);
})
.addItem(\dipped,{
	c.set(\grainSmooth,~dippedSmooth);
})
.addItem(\constant,{
	c.set(\grainSmooth,~constantpowerSmooth);
});

menuEnv3 = EZPopUpMenu(parentView: w,bounds:Rect(420,370,60,22))
.setColors(menuBackground: ~black, menuStringColor: ~color3)
.addItem(\Hann,{
	u.set(\grainSmooth,-1);
})
.addItem(\fastCut,{
	u.set(\grainSmooth,~fastcutSmooth);
})
.addItem(\perc,{
	u.set(\grainSmooth,~percSmooth);
})
.addItem(\trans,{
	u.set(\grainSmooth,~transSmooth);
})
.addItem(\dipped,{
	u.set(\grainSmooth,~dippedSmooth);
})
.addItem(\constant,{
	u.set(\grainSmooth,~constantpowerSmooth);
});

/*
p = Button(parent: w, bounds: Rect(10,600,60,30))
.states_([
	[" ", Color.gray, ~color1];
])
.action_(
	{
		if(channel1 ==1, {
			t.run();
			t.set(\t_gate,1);
		});

		if (channel2==1,{
			c.run();
			c.set(\t_gate,1);
		});

		if(channel3==1, {
			u.run();
			u.set(\t_gate,1);
		});

});
*/

w.view.keyDownAction =
	{

		if(channel1 ==1, {
			t.run();
			t.set(\t_gate,1);
		});

		if (channel2==1,{
			c.run();
			c.set(\t_gate,1);
		});

		if(channel3==1, {
			u.run();
			u.set(\t_gate,1);
		});
};

//p.focusColor = ~color2;
//p.background = ~color1;



//Channel/synth volume slider

~sliderS1 = Slider.new(w, Rect(500,5,30,150))
.focusColor_(~color1)
.background_(Color.black)
.knobColor_(~color1)
.thumbSize_(5)
.value_(0.5)
.action_({
	arg obj;
	var cf;
	cf = obj.value.postln;
	t.set(\amp,cf.linlin(0,1,0,1));
});

~sliderS2 = Slider.new(w, Rect(500,200,30,150))
.focusColor_(~color2)
.background_(Color.black)
.knobColor_(~color2)
.thumbSize_(5)
.value_(0.5)
.action_({
	arg obj;
	var cf;
	cf = obj.value.postln;
	c.set(\amp,cf.linlin(0,1,0,1));
});


~sliderS3 = Slider.new(w, Rect(500,370,30,150))
.focusColor_(~color3)
.background_(Color.black)
.knobColor_(~color3)
.thumbSize_(5)
.value_(0.5)
.action_({
	arg obj;
	var cf;
	cf = obj.value.postln;
	u.set(\amp,cf.linlin(0,1,0,1));
});


/// ADSR boxes

boxAtk = NumberBox(w, Rect(450, 35, 30, 20))
.background_(Color.black)
.normalColor_(~color1)
.typingColor_(Color.green)
.scroll_step_(0.01)
.clipLo_(0);

    boxAtk.value = 0.5;
    boxAtk.action = {arg numb;
	t.set(\atk, (boxAtk.value))
};

boxDcy = NumberBox(w, Rect(450, 57, 30, 20))
.background_(Color.black)
.normalColor_(~color1)
.typingColor_(Color.green)
.scroll_step_(0.01)
.clipLo_(0);
    boxDcy.value = 0.5;

    boxDcy.action = {arg numb;
	t.set(\dcy, (boxDcy.value))
};


boxSst = NumberBox(w, Rect(450, 79, 30, 20))
.background_(Color.black)
.normalColor_(~color1)
.typingColor_(Color.green)
.scroll_step_(0.02)
.clipLo_(0);
    boxSst.value = 1;
    boxSst.action = {arg numb;
	t.set(\sst, (boxSst.value))
};

boxRls = NumberBox(w, Rect(450, 101, 30, 20))
.background_(Color.black)
.normalColor_(~color1)
.typingColor_(Color.green)
.scroll_step_(0.01)
.clipLo_(0);
    boxRls.value = 0.5;
    boxRls.action = {arg numb;
	t.set(\rls, (boxRls.value))
};

boxAtk2 = NumberBox(w, Rect(450, 227, 30, 20))
.background_(Color.black)
.normalColor_(~color2)
.typingColor_(Color.green)
.scroll_step_(0.01)
.clipLo_(0);
    boxAtk2.value = 0.5;
    boxAtk2.action = {arg numb;
	c.set(\atk, (boxAtk2.value))
};

boxDcy2 = NumberBox(w, Rect(450, 249, 30, 20))
.background_(Color.black)
.normalColor_(~color2)
.typingColor_(Color.green)
.scroll_step_(0.01)
.clipLo_(0);
    boxDcy2.value = 0.5;

    boxDcy2.action = {arg numb;
	c.set(\dcy, (boxDcy2.value))
};


boxSst2 = NumberBox(w, Rect(450, 271, 30, 20))
.background_(Color.black)
.normalColor_(~color2)
.typingColor_(Color.green)
.scroll_step_(0.02)
.clipLo_(0);
    boxSst2.value = 1;
    boxSst2.action = {arg numb;
	c.set(\sst, (boxSst2.value))
};

boxRls2 = NumberBox(w, Rect(450, 293, 30, 20))
.background_(Color.black)
.normalColor_(~color2)
.typingColor_(Color.green)
.scroll_step_(0.01)
.clipLo_(0);
    boxRls2.value = 0.5;
    boxRls2.action = {arg numb;
	c.set(\rls, (boxRls2.value))
};

boxAtk3 = NumberBox(w, Rect(450, 395, 30, 20))
.background_(Color.black)
.normalColor_(~color3)
.typingColor_(Color.green)
.scroll_step_(0.01)
.clipLo_(0);
    boxAtk3.value = 0.5;
    boxAtk3.action = {arg numb;
	u.set(\atk, (boxAtk3.value))
};

boxDcy3 = NumberBox(w, Rect(450, 419, 30, 20))
.background_(Color.black)
.normalColor_(~color3)
.typingColor_(Color.green)
.scroll_step_(0.01)
.clipLo_(0);
    boxDcy3.value = 0.5;
    boxDcy3.action = {arg numb;
	u.set(\dcy, (boxDcy3.value))
};


boxSst3 = NumberBox(w, Rect(450, 446, 30, 20))
.background_(Color.black)
.normalColor_(~color3)
.typingColor_(Color.green)
.scroll_step_(0.01)
.clipLo_(0);
    boxSst3.value = 1;
    boxSst3.action = {arg numb;
	u.set(\sst, (boxSst3.value))
};

boxRls3 = NumberBox(w, Rect(450, 473, 30, 20))
.background_(Color.black)
.normalColor_(~color3)
.typingColor_(Color.green)
.scroll_step_(0.01)
.clipLo_(0);
    boxRls3.value = 0.5;
    boxRls3.action = {arg numb;
	u.set(\rls, (boxRls3.value))
};



///////////////"GRAPHIC EQ"

num = 10;


~gEq = MultiSliderView(w,Rect(550,10,num*13+2,100));
~gEq.isFilled=true;
~gEq.strokeColor = Color.fromHexString("09D2EC");
~gEq.fillColor = Color.fromHexString("8005AD");
~gEq.background = Color.black;
~gEq.drawLines = true;
~gEq.thumbSize = 6;
~gEq.elasticMode = 1;
~gEq.value=[0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5];
~gEq.action ={
	arg obj;
	obj.value.postln;
	t.set(\amp0, obj.value[0]);
	t.set(\amp1, obj.value[1]);
	t.set(\amp2, obj.value[2]);
	t.set(\amp3, obj.value[3]);
	t.set(\amp4, obj.value[4]);
	t.set(\amp5, obj.value[5]);
	t.set(\amp6, obj.value[6]);
	t.set(\amp7, obj.value[7]);
	t.set(\amp8, obj.value[8]);
	t.set(\amp9, obj.value[9]);
};


~gEq2 = MultiSliderView(w,Rect(550,200,num*13+2,100));
~gEq2.isFilled=true;
~gEq2.strokeColor = Color.fromHexString("F76106");
~gEq2.fillColor = Color.fromHexString("77F32B");
~gEq2.background = Color.black;
~gEq2.drawLines = true;
~gEq2.thumbSize = 6;
~gEq2.elasticMode = 1;
~gEq2.value=[0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5];
~gEq2.action ={
	arg obj;
	obj.value.postln;
	c.set(\amp0, obj.value[0]);
	c.set(\amp1, obj.value[1]);
	c.set(\amp2, obj.value[2]);
	c.set(\amp3, obj.value[3]);
	c.set(\amp4, obj.value[4]);
	c.set(\amp5, obj.value[5]);
	c.set(\amp6, obj.value[6]);
	c.set(\amp7, obj.value[7]);
	c.set(\amp8, obj.value[8]);
	c.set(\amp9, obj.value[9]);
};


~gEq3 = MultiSliderView(w,Rect(550,370,num*13+2,100));
~gEq3.isFilled=true;
~gEq3.strokeColor = Color.fromHexString("57F706");
~gEq3.fillColor = Color.fromHexString("F70618");
~gEq3.background = Color.black;
~gEq3.drawLines = true;
~gEq3.thumbSize = 6;
~gEq3.elasticMode = 1;
~gEq3.value=[0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5];
~gEq3.action ={
	arg obj;
	obj.value;
	u.set(\amp0, obj.value[0]);
	u.set(\amp1, obj.value[1]);
	u.set(\amp2, obj.value[2]);
	u.set(\amp3, obj.value[3]);
	u.set(\amp4, obj.value[4]);
	u.set(\amp5, obj.value[5]);
	u.set(\amp6, obj.value[6]);
	u.set(\amp7, obj.value[7]);
	u.set(\amp8, obj.value[8]);
	u.set(\amp9, obj.value[9]);
};


///LABELS KNOBS

//Channel 1
~densTxt1 = StaticText.new(w, Rect(posH1, posV1, 35,20))
.string_("Density")
.stringColor_(~color1)
.align_(\center);

~lenTxt1 = StaticText.new(w, Rect(posH1+distH, posV1, 35,20))
.string_("Length")
.stringColor_(~color1)
.align_(\center);

///GrainBuf
~pitchTxt1 = StaticText.new(w, Rect(posH1, posV1+distV, 35,20))
.string_("Pitch")
.stringColor_(~color1)
.align_(\center);

~decTxt1 = StaticText.new(w, Rect(posH1+distH, posV1+distV, 40,20))
.string_("Sampling")
.stringColor_(~color1)
.align_(\center);


//Channel 2

~densTxt2 = StaticText.new(w, Rect(posH2, posV2, 35,20))
.string_("Density")
.stringColor_(~color2)
.align_(\center);

~lenTxt2 = StaticText.new(w, Rect(posH2+distH, posV2, 35,20))
.string_("Length")
.stringColor_(~color2)
.align_(\center);

///GrainBuf
~pitchTxt2 = StaticText.new(w, Rect(posH2, posV2+distV, 35,20))
.string_("Pitch")
.stringColor_(~color2)
.align_(\center);

~decTxt2 = StaticText.new(w, Rect(posH2+distH, posV2+distV, 40,20))
.string_("Sampling")
.stringColor_(~color2)
.align_(\center);


//Channel 3

~densTxt3 = StaticText.new(w, Rect(posH3, posV3, 35,20))
.string_("Density")
.stringColor_(~color3)
.align_(\center);

~lenTxt3 = StaticText.new(w, Rect(posH3+distH, posV3, 35,20))
.string_("Length")
.stringColor_(~color3)
.align_(\center);

///GrainBuf
~pitchTxt3 = StaticText.new(w, Rect(posH3, posV3+distV, 35,20))
.string_("Pitch")
.stringColor_(~color3)
.align_(\center);

~decTxt3 = StaticText.new(w, Rect(posH3+distH, posV3+distV, 40,20))
.string_("Sampling")
.stringColor_(~color3)
.align_(\center);

//ENVELOPES/

~atckTxt1 = StaticText.new(w, Rect(420,35,30,20))
.string_("Atk")
.stringColor_(~color1)
.align_(\center);

~dcyTxt1 = StaticText.new(w, Rect(420,57,30,20))
.string_("Dcy")
.stringColor_(~color1)
.align_(\center);

///GrainBuf
~sstTxt1 = StaticText.new(w, Rect(420,79,30,20))
.string_("Sst")
.stringColor_(~color1)
.align_(\center);

~rlsTxt1 = StaticText.new(w, Rect(420,101,30,20))
.string_("Rls")
.stringColor_(~color1)
.align_(\center);

//Channel 2

~atckTxt2 = StaticText.new(w, Rect(420,227,30,20))
.string_("Atk")
.stringColor_(~color2)
.align_(\center);

~dcyTxt2 = StaticText.new(w, Rect(420,249,30,20))
.string_("Dcy")
.stringColor_(~color2)
.align_(\center);

///GrainBuf
~sstTxt2 = StaticText.new(w, Rect(420,271,30,20))
.string_("Sst")
.stringColor_(~color2)
.align_(\center);

~rlsTxt2 = StaticText.new(w, Rect(420,293,30,20))
.string_("Rls")
.stringColor_(~color2)
.align_(\center);

//Channel 3

~atckTxt3 = StaticText.new(w, Rect(420,395,30,20))
.string_("Atk")
.stringColor_(~color3)
.align_(\center);

~dcyTxt3 = StaticText.new(w, Rect(420,419,30,20))
.string_("Dcy")
.stringColor_(~color3)
.align_(\center);

///GrainBuf
~sstTxt3 = StaticText.new(w, Rect(420,446,30,20))
.string_("Sst")
.stringColor_(~color3)
.align_(\center);

~rlsTxt3 = StaticText.new(w, Rect(420,473,30,20))
.string_("Rls")
.stringColor_(~color3)
.align_(\center);


//Presets

~presetMenu = StaticText.new(w, Rect(5, 580, 60,20))
.string_("PRESETS")
.stringColor_(~color1)
.align_(\center);

~presets=EZPopUpMenu(w, Rect(10,550, 100,30))
.setColors(menuBackground: ~color1)
.addItem(\None,{

})
.addItem(\Footsteps, {

	g.value = 3;

	channel1 = 1;
	channel2 = 0;
	channel3 = 0;
	t.free;
	{t = Synth.newPaused(\GrainInSample,[
		\bus,5,
		\grainDens,92,
		\grainLength,0.05,
		\noiseType, 5,
		\sr, 16000,
		\grainSmooth,~percSmooth,
		\atk, 0,
		\dcy, 0.06,
		\sst, 0.02,
		\rls, 0.01,
		\amp0, 0.36,
		\amp1, 0.22,
		\amp2, 0.14,
		\amp3, 0.096,
		\amp4, 0,
		\amp5, 0,
		\amp6, 0,
		\amp7, 0,
		\amp8, 0,
		\amp9, 0,
	])}.defer(0.2);
	~grainBufScope.start;

	//Managing knobs on GUI

	~pitchS1.visible = false;
	~frqS1.visible = false;
	~modS1.visible = false;
	~typeNS1.visible = true;
	~decS1.visible = true;

	~pitchTxt1.string_("Type");
	~decTxt1.string_("Sampling");

	~densS1.value_(0.26);
	~sizeS1.value_(0.05);
	~typeNS1.value_(1);
	~decS1.value_(1);

	menuEnv1.value=2;

	boxAtk.value = 0;
	boxDcy.value =0.06;
	boxSst.value = 0.02;
	boxRls.value = 0.01;
	~gEq.value=[0.36,0.22,0.14,0.096,0,0,0,0,0,0];



})
.addItem(\Cricket,{

	g.value = 3;

	channel1 = 1;
	channel2 = 0;
	channel3 = 0;
	t.free;
	{t = Synth.newPaused(\GrainInSample,[
		\bus,5,
		\grainDens,92,
		\grainLength,0.05,
		\noiseType, 5,
		\sr, 4192,
		\grainSmooth,~percSmooth,
		\atk, 0,
		\dcy, 0.06,
		\sst, 0.04,
		\rls, 0.01,
		\amp0, 0.36,
		\amp1, 0.20,
		\amp2, 0.095,
		\amp3, 0.053,
		\amp4, 0,
		\amp5, 0,
		\amp6, 0,
		\amp7, 0,
		\amp8, 0,
		\amp9, 0,
	])}.defer(0.2);
	~grainBufScope.start;

	//Managing knobs on GUI

	~pitchS1.visible = false;
	~frqS1.visible = false;
	~modS1.visible = false;
	~typeNS1.visible = true;
	~decS1.visible = true;

	~pitchTxt1.string_("Type");
	~decTxt1.string_("Sampling");

	//Setting values on gui

	~densS1.value_(0.92);
	~sizeS1.value_(0.05);
	~typeNS1.value_(1);
	~decS1.value_(4192.linlin(256,16000,0,1));

	menuEnv1.value=2;

	boxAtk.value = 0;
	boxDcy.value =0.06;
	boxSst.value = 0.04;
	boxRls.value = 0.01;
	~gEq.value=[0.36,0.20,0.095,0.053,0,0,0,0,0,0];


})
.addItem(\Spooky, {

	g.value = 2;
	channel1 = 1;
	channel2 = 0;
	channel3 = 0;
	t.free;
	{t = Synth.newPaused(\GrainFMSample,[
		\bus,5,
		\grainDens,76.31,
		\grainLength,0.28,
		\grainSmooth,-1,
		\freqCtrl, 358,
		\modFreq,400,
		\atk, 0.5,
		\dcy, 6,
		\sst, 5,
		\rls, 4,
		\amp0, 0.42,
		\amp1, 0.53,
		\amp2, 0.67,
		\amp3, 0.24,
		\amp4, 0.02,
		\amp5, 0,
		\amp6, 0,
		\amp7, 0,
		\amp8, 0,
		\amp9, 0,
		])}.defer(0.2);
		//Plot initialization
		~grainBufScope.start;

		//Managing knobs on GUI
		~pitchS1.visible = false;
		~frqS1.visible = true;
		~modS1.visible = true;
		~typeNS1.visible = false;
		~decS1.visible = false;

		~pitchTxt1.string_("Freq");
		~decTxt1.string_("Mod");

	menuEnv1.value=0;
	~densS1.value_(0.21);
	~sizeS1.value_(0.28);
	~frqS1.value_(0.3);
	~modS1.value_(0.65);
	boxAtk.value = 0.5;
	boxDcy.value =6;
	boxSst.value = 5;
	boxRls.value = 4;
	~gEq.value=[0.42,0.53,0.67,0.24,0.02,0,0,0,0,0];

})
.addItem(\CreepGlass,{
	channel1 = 1;
	channel2 = 0;
	channel3 = 0;
	g.value = 1;

	~sample1 = (~path +/+ "./samples/vox.wav");
	b.free;
	b = Buffer.readChannel(s, ~sample1, channels: [0]);

	{t = Synth.newPaused(\GrainBufSample,[
		\buff, b,
		\bus,5,
		\grainDens, 10,
		\grainLength,0.03,
		\grainSmooth,~percSmooth,
		\playRate, 1.24,
		\sr, 7655,
		\atk, 0.01,
		\dcy, 1,
		\sst, 1,
		\rls, 6,
		\amp0, 0.75,
		\amp1, 0.40,
		\amp2, 0.17,
		\amp3, 0,
		\amp4, 0,
		\amp5, 0,
		\amp6, 0,
		\amp7, 0,
		\amp8, 0,
		\amp9, 0,
	])}.defer(0.2);

	//Plot initialization
	~grainBufScope.start;


		//Managing knobs on GUI

	~pitchS1.visible = true;
	~frqS1.visible = false;
	~modS1.visible = false;
	~typeNS1.visible = false;
	~decS1.visible = true;

	~pitchTxt1.string_("Pitch");
	~decTxt1.string_("Sampling");

	menuEnv1.value=2;
	~densS1.value_(0.025);
	~sizeS1.value_(0.03);
	~pitchS1.value_(0.62);
	~decS1.value_(0.47);

	boxAtk.value = 0.01;
	boxDcy.value =1;
	boxSst.value = 1;
	boxRls.value = 0.6;
	~gEq.value=[0.75,0.40,0.17,0,0,0,0,0,0,0];
})
.addItem(\Explosion,{
	channel1 = 1;
	channel3 = 0;
	g.value = 1;

	~sample1 = (~path +/+ "./samples/vox.wav");
	//soundFile = SoundFile.new;
	//soundFile.openRead(path);
	b.free;
	b = Buffer.readChannel(s, ~sample1, channels: [0]);

	{t = Synth.newPaused(\GrainBufSample,[
		\buff, b,
		\bus,5,
		\grainDens, 350,
		\grainLength,1,
		\grainSmooth,~percSmooth,
		\playRate, 1.98,
		\sr, 4664.32,
		\atk, 0.01,
		\dcy, 0,
		\sst, 0.02,
		\rls, 1.04,
		\amp0, 0.51,
		\amp1, 0.52,
		\amp2, 0.54,
		\amp3, 0.091,
		\amp4, 0.031,
		\amp5, 0.010,
		\amp6, 0.010,
		\amp7, 0,
		\amp8, 0,
		\amp9, 0.031,
	])}.defer(0.2);

	//Plot initialization
	~grainBufScope.start;

	//Managing knobs on GUI

	~pitchS1.visible = true;
	~frqS1.visible = false;
	~modS1.visible = false;
	~typeNS1.visible = false;
	~decS1.visible = true;

	~pitchTxt1.string_("Pitch");
	~decTxt1.string_("Sampling");

	menuEnv1.value=2;
	~densS1.value_(1);
	~sizeS1.value_(1);
	~pitchS1.value_(1);
	~decS1.value_(0.28);

	boxAtk.value = 0.01;
	boxDcy.value =0;
	boxSst.value = 0.02;
	boxRls.value = 1.04;
	~gEq.value=[0.51,0.52,0.54,0.091,0.031,0.010,0.010,0,0,0.031];

	// channel 2
	channel2=1;
	h.value=2;
	c.free;
	{c = Synth.newPaused(\GrainFMSample,[
		\bus,8,
		\grainDens,350,
		\grainLength,1,
		\grainSmooth,~percSmooth,
		\freqCtrl, 80,
		\modFreq,20,
		\atk, 0.01,
		\dcy, 0,
		\sst, 0.02,
		\rls, 1.04,
		\amp0, 0.07,
		\amp1, 0.17,
		\amp2, 0.17,
		\amp3, 0.18,
		\amp4, 0.20,
		\amp5, 0.23,
		\amp6, 0.28,
		\amp7, 0.33,
		\amp8, 0.42,
		\amp9, 0.58,
	])}.defer(0.2);
		//Plot initialization
	~grainFMScope.start;

	~pitchS2.visible = false;
	~frqS2.visible = true;
	~modS2.visible = true;
	~typeNS2.visible = false;
	~decS2.visible = false;

	~pitchTxt2.string_("Freq");
	~decTxt2.string_("Mod");

	menuEnv1.value=2;
	~densS2.value_(1);
	~sizeS2.value_(1);
	~frqS2.value_(0);
	~modS2.value_(1);
	boxAtk2.value = 0.01;
	boxDcy2.value =0;
	boxSst2.value = 0.02;
	boxRls.value = 1.04;
	~gEq2.value=[0.07,0.17,0.17,0.18,0.20,0.23,0.28,0.33,0.42,0.58];

})
.addItem(\RainWind, {
	g.value = 3;
	h.value = 2;
	o.value = 1;

	channel1 = 1;
	channel2 = 1;
	channel3 = 1;
	t.free;
	{t = Synth.newPaused(\GrainInSample,[
		\bus,5,
		\grainDens,10,
		\grainLength,0.03,
		\noiseType, 0,
		\sr, 16000,
		\grainSmooth,~percSmooth,
		\atk, 0.5,
		\dcy, 0.5,
		\sst, 1,
		\rls, 1,
		\amp0, 1.0,
		\amp1, 0.404,
		\amp2, 0,
		\amp3, 0,
		\amp4, 0,
		\amp5, 0,
		\amp6, 0,
		\amp7, 0,
		\amp8, 0,
		\amp9, 0,
	])}.defer(0.2);
	~grainBufScope.start;
	c.free;
	{c = Synth.newPaused(\GrainFMSample,[
		\bus,8,
		\grainDens,296,
		\grainLength, 0.479,
		\grainSmooth, -1,
		\modFreq, 20,
		\freqCtrl,80,
		\atk, 0.1,
		\dcy, 0.01,
		\sst, 1,
		\rls, 0.1,
		\amp0, 0.436,
		\amp1, 0.776,
		\amp2, 0,
		\amp3, 0,
		\amp4, 0,
		\amp5, 0,
		\amp6, 0,
		\amp7, 0,
		\amp8, 0,
		\amp9, 0,
	])}.defer(0.2);
	//Plot initialization
	~grainFMScope.start;

	~sample2 = (~path +/+ "./samples/song.wav");
	q.free;
	u.free;
	q = Buffer.readChannel(s, ~sample2, channels: [0]);
	{u = Synth.newPaused(\GrainBufSample,[
		\buff, q,
		\bus,11,
		\grainDens,350,
		\grainLength, 0.5,
		\playRate, 0.04,
		\sr,16000,
		\grainSmooth, -1,
		\atk, 1.2,
		\dcy, 0.2,
		\sst, 0.1,
		\rls, 1,
		\amp0, 0.489,
		\amp1, 0.063,
		\amp2, 0,
		\amp3, 0,
		\amp4, 0,
		\amp5, 0,
		\amp6, 0,
		\amp7, 0,
		\amp8, 0,
		\amp9, 0,
	])}.defer(0.2);
	//Plot initialization
	~grainInScope.start;

	//Managing knobs on GUI

	~pitchS1.visible = false;
	~frqS1.visible = false;
	~modS1.visible = false;
	~typeNS1.visible = true;
	~decS1.visible = true;

	~pitchS2.visible = false;
	~frqS2.visible = true;
	~modS2.visible = true;
	~typeNS2.visible = false;
	~decS2.visible = false;

	~pitchS3.visible = false;
	~frqS3.visible = true;
	~modS3.visible = true;
	~typeNS3.visible = false;
	~decS3.visible = false;

	~pitchTxt1.string_("Type");
	~decTxt1.string_("Sampling");

	~pitchTxt2.string_("Freq");
	~decTxt2.string_("Mod");

	~pitchTxt3.string_("Pitch");
	~decTxt3.string_("Sampling");

	~densS1.value_(0.025);
	~sizeS1.value_(0.03);
	~typeNS1.value_(0.0);
	~decS1.value_(1);

	~densS2.value_(0.84);
	~sizeS2.value_(0.479);
	~frqS2.value_(0);
	~modS2.value_(1);

	~densS3.value_(1);
	~sizeS3.value_(0.5);
	~pitchS3.value_(0.02);
	~decS3.value_(1);


	menuEnv1.value=2;
	boxAtk.value = 0.5;
	boxDcy.value =0.5;
	boxSst.value = 1;
	boxRls.value = 1;
	~gEq.value=[1.0,0.404,0,0,0,0,0,0,0,0];


	menuEnv2.value=0;
	boxAtk2.value = 0.1;
	boxDcy2.value =0.01;
	boxSst2.value = 1;
	boxRls2.value = 0.1;
	~gEq2.value=[0.436,0.776,0,0,0,0,0,0,0,0];


	menuEnv3.value=0;
	boxAtk3.value = 1.2;
	boxDcy3.value =0.2;
	boxSst3.value = 0.1;
	boxRls3.value = 1;
	~gEq3.value=[0.489,0.063,0,0,0,0,0,0,0,0];
})
.addItem(\LaserGun,{

	channel1 = 1;
	channel3 = 0;
	g.value = 1;

	~sample1 = (~path +/+ "./samples/vox.wav");
	b.free;
	t.free;
	b = Buffer.readChannel(s, ~sample1, channels: [0]);
	{t = Synth.newPaused(\GrainBufSample,[
		\buff, b,
		\bus,5,
		\grainDens, 350,
		\grainLength,1,
		\grainSmooth,~percSmooth,
		\playRate, 1.32,
		\sr, 3247.36,
		\atk, 0,
		\dcy, 0,
		\sst, 0.02,
		\rls, 0.29,
		\amp0, 0.3,
		\amp1, 0.11,
		\amp2, 0.25,
		\amp3, 0.28,
		\amp4, 0.35,
		\amp5, 0.44,
		\amp6, 0.53,
		\amp7, 0.61,
		\amp8, 0.69,
		\amp9, 0.81,
	])}.defer(0.2);

	//Plot initialization
	~grainBufScope.start;

		//Managing knobs on GUI

	~pitchS1.visible = true;
	~frqS1.visible = false;
	~modS1.visible = false;
	~typeNS1.visible = false;
	~decS1.visible = true;

	~pitchTxt1.string_("Pitch");
	~decTxt1.string_("Sampling");

	menuEnv1.value=2;
	~densS1.value_(1);
	~sizeS1.value_(1);
	~pitchS1.value_(0.66);
	~decS1.value_(0.19);

	boxAtk.value = 0;
	boxDcy.value =0;
	boxSst.value = 0.02;
	boxRls.value = 0.29;
	~gEq.value=[0.3,0.11,0.25,0.28,0.35,0.44,0.53,0.61,0.69,0.81];

	// channel 2
	channel2=1;
	h.value=2;
	c.free;
	{c = Synth.newPaused(\GrainFMSample,[
		\bus,8,
		\grainDens,350,
		\grainLength,1,
		\grainSmooth,-1,
		\freqCtrl, 604,
		\modFreq,20,
		\atk, 0.01,
		\dcy, 0,
		\sst, 0.02,
		\rls, 0.38,
		\amp0, 0.4,
		\amp1, 0.4,
		\amp2, 0.38,
		\amp3, 0.38,
		\amp4, 0.39,
		\amp5, 0.42,
		\amp6, 0.45,
		\amp7, 0.49,
		\amp8, 0.54,
		\amp9, 0.59,
	])}.defer(0.2);
		//Plot initialization
	~grainFMScope.start;

	~pitchS2.visible = false;
	~frqS2.visible = true;
	~modS2.visible = true;
	~typeNS2.visible = false;
	~decS2.visible = false;

	~pitchTxt2.string_("Freq");
	~decTxt2.string_("Mod");

	menuEnv1.value=2;
	~densS2.value_(1);
	~sizeS2.value_(1);
	~frqS2.value_(0.57);
	~modS2.value_(1);
	boxAtk2.value = 0.01;
	boxDcy2.value =0;
	boxSst2.value = 0.02;
	boxRls.value = 1.04;
	~gEq2.value=[0.4,0.4,0.38,0.38,0.39,0.42,0.45,0.49,0.54,0.59];

});


)

//// END

