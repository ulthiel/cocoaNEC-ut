//G5RV model for cocoaNEC
//by Ulrich Thiel, DK1UT
//Mar 2020

model("g5rv")
{
	//variable declarations
	real height, height_l, height_r, length, theta, d;
	vector leg_r_start, leg_r_end, leg_l_start, leg_l_end, feed_start, feed_end;
	transform T;
	element feed;
	
	//height of center of antenna
	height = 7;
	
	//height of end of leg above ground
	height_r = 0.3;
	height_l = 1.5;
	
	//total length of antenna (both legs)
	length = 31.5;
		
	//angle between the two legs
	theta = 106;
	
	//ground
	ground(4.65, 0.012);

	//compute feed
	//this is just a small segment (of length 2d) at height
	d = 0.02;
	feed_start = vect(-d,0,height);
	feed_end = vect(d,0,height);
	feed = wirev( nil, feed_start, feed_end, #14, 3 );
			
	//compute right leg
	leg_r_start = vect(d,0,height);
	leg_r_end = vect(d+sqrt( (length*length) - (height-height_r)*(height-height_r) ), 0, height_r);
	wirev(nil, leg_r_start, leg_r_end, #14, 21);
	
	//compute left leg
	leg_l_start = vect(-d,0,height);
	leg_l_end = vect(-d-sqrt( (length*length) - (height-height_l)*(height-height_l) ), 0, height_l);
	T = rotateZ(180-theta);
	leg_l_end = T*leg_l_end;
	wirev(nil, leg_l_start, leg_l_end, #14, 21);


	//setFrequency(3.7);
	setFrequency(7.1);
	azimuthPlotForElevationAngle( 20);
	voltageFeed(feed, 1.0, 0.0 ) ;	
}