//--------------------------------------------------------------------------------------------------
// 2018 - ELENA D'ALÒ - AdrGuar
//--------------------------------------------------------------------------------------------------

declare name "Dissolto";
declare version "0.1";
declare author "Elena D'Alò";
declare copyright "Elena D'Alò 2018";
declare license "BSD";
declare reference "daloele@gmail.com";
declare description "AMBIENTE ESECUTIVO";

import("stdfaust.lib");

// =======================================================
// ========================================== STAGE PLAN =
// =======================================================

//---1-------2---
//---3-------3---
//------pf-------
//---5-------6---
//---7-------8---
//-----regia-----

// =======================================================
// ====================================== GS DEFINITIONS =
// =======================================================

vmeter(x)	= attach(x, envelop(x) : vbargraph("[unit:dB]", -70, 0));
hmeter(x)	= attach(x, envelop(x) : hbargraph("[unit:dB]", -70, 0));
  envelop = abs : max(ba.db2linear(-70)) : ba.linear2db : min(10)  : max ~ -(80.0/ma.SR);
  mt2samp = *(343.00/ma.SR); // into acoustics.lib - ac.mt2samp

// =======================================================
// =================== INPUTS SELECTOR FF800 26 I - 26 O =
// ============================ ADAT IO STARTING FROM 13 =
// =======================================================

ainputs = si.bus(26); // 26 INPUTS

  piano = si.block(12),
          si.bus(2),    // SELECT 13 and 14 (FF800 ADAT 1 and 2)
          si.block(12);

// =======================================================
// ================================================= DSP =
// =======================================================

edamp = amp
  with {
    amp = si.bus(2) : hmeter, hmeter;
  }; // qui puoi mettere equalizzatori o filtraggi o quello che vuoi per l'amplificazione

edelf = par(i, 2, voice)
	with
	{
		voice 	= (+ : de.sdelay(N, interp, dtime)) ~ *(fback);
		N 		  = int(2^19);
		interp 	= hslider("interpolation[unit:ms][style:knob]",10,1,100,0.1)*ma.SR/1000.0;
		dtime	  = hslider("delay[unit:ms][style:knob]", 0, 0, 5000, 0.1)*ma.SR/1000.0;
		fback 	= hslider("feedback[style:knob]",0,0,100,0.1)/100.0;
	};

// sdelay: s è smooth, un delay interpolato che non fa rumore al variare della sua lunghezza

edharm = harm
  with {
    harm = si.bus(2) : hmeter, hmeter;
  };

edrev = dm.zita_rev1;

// =======================================================
// ================= Audio Matrix : N inputs x M outputs =
// =======================================================

Fader(in)    = ba.db2linear(vslider("Input %in", -10, -96, 4, 0.1));

Mixer(N,out) = hgroup("Output %out", par(in, N, *(Fader(in)) ) :> _ );
// genera un canale di mix per ogni bus di entrata e sommarli tutti su una uscita

Matrix(N,M)  = tgroup("Matrix %N x %M", par(in, N, _) <: par(out, M, Mixer(N, out)));

edmtx = Matrix(8, 8);

// =======================================================

process = ainputs : piano <: edamp , edelf, edharm, edrev : edmtx ;
