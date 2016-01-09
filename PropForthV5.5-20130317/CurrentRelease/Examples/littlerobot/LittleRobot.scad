tap632 =0.106*25.4/2;
tap832 =0.136*25.4/2;
through632=0.144*25.4/2;
through832=0.173*25.4/2;

// print_wheel();
// print_base();
// print_case();
// print_cb_mount();


bot();



module bot()
{
	color("silver") steppers();
	color("black") tailwheel();
	color("red") wheels();
	color("green") batterypack();
	mounted_board(rotation=0,lift=0);
//	mounted_board(rotation=-60,lift=18);
//	mounted_board(rotation=-90,lift=18);
//	mounted_board(rotation=-90,lift=18);

	color("white") case();
	color("blue") base();
}



module qstart()
{
	rotate([0,0,180])difference()
	{
		union()
		{
			translate([0,19,4.5]) cube(size=[51,5,7],center=true);
			cube(size=[78,52,2],center=true);
		}	
		for( i = [-1,1]){
			for(j=[-1,1]) {
				translate([i*2.75*25.4/2,j*1.75*25.4/2,0]) cylinder(h=10,r=0.125*25.4/2,center=true,$fn=50);
			}
		}
	}
}



module print_wheel()
{
	translate( [0,0,3]) wheel(40,6);
}

module print_base()
{
	translate([0,0,17]) base();
}
module print_case()
{
	translate([0,0,18]) mirror([0,0,1]) case();
}

module print_cb_mount()
{
	translate([7,-8,2.5])rotate([0,90,0]) cb_mount(rotation=0, lift=0);
	mirror([1,0,0])translate([-27,-8,2.5])rotate([0,90,0]) cb_mount(rotation=0, lift=0);
}

module case()
{
	translate([0,17,3])

	difference()
	{	
		union()
		{
			difference()
			{	
		
		// block
				minkowski()
				{
					difference()
					{
						cube(size=[88,100,25],center=true);
						translate([0,40,0]) cube(size=[75.5,30,30],center=true);
					}
					cylinder(h=5,r=10,center=true,$fn=50);
				}
		// right stepper cutout
				translate([42,-17,-3]) rotate([0,90,0]) cylinder(h=25,r=14.5,center=true,$fn=50);
				translate([42,-17,-15]) cube(size=[25,20,12],center=true);
		
		// left stepper cutout
				translate([-42,-17,-3]) rotate([0,90,0]) cylinder(h=25,r=14.5,center=true,$fn=50);
				translate([-42,-17,-15]) cube(size=[25,20,12],center=true);
		// front 8-32 tap for steppers
				translate([0,-34.5,-3]) rotate([0,90,0]) cylinder(h=150,r=through632,center=true,$fn=50);
		// rear 8-32 tap for steppers
				translate([0,0.5,-3]) rotate([0,90,0]) cylinder(h=150,r=through632,center=true,$fn=50);
		
		// - battery case
				translate([0,-25,0]) cube(size=[88,60,35],center=true);
		
		// - tailwheel
				translate([0,40,0])  cylinder(h=30,r=28,center=true,$fn=50);
				translate([0,20,0]) difference()
				{
					cube(size=[80,30,30],center=true);
					translate([0,20,0])  cylinder(h=30,r=33,center=true,$fn=50);
				}
		// - left and right areas
				minkowski()
				{
					translate([41,0,0])cube(size=[7.5,100,25],center=true);
					cylinder(h=5,r=5,center=true,$fn=50);
				}
				minkowski()
				{
					translate([-41,0,0])cube(size=[7.5,100,25],center=true);
					cylinder(h=5,r=5,center=true,$fn=50);
				}
		
		
			}
		// tailwheel mount
			translate([0,38,0]) difference()
			{
				union()
				{
					translate([0,0,10])  cylinder(h=10,r=30,center=true,$fn=50);
					translate([0, 5,10]) cube(size=[74,26,10],center=true);
					translate([0, -13,10]) cube(size=[108,15,10],center=true);
				}
				translate([0, 28,5]) cube(size=[90,12,20],center=true);
		
		// rear 6-32 tap for tailwheel
				translate([12,15,12]) cylinder(h=15,r=tap632,center=true,$fn=50);
				translate([12,-15,12]) cylinder(h=15,r=tap632,center=true,$fn=50);
				translate([-12,15,12]) cylinder(h=15,r=tap632,center=true,$fn=50);
				translate([-12,-15,12]) cylinder(h=15,r=tap632,center=true,$fn=50);
			}
	
		}
// 6-32 taps for rear circuit board mount
		translate([38,44,8]) rotate([0,90,0])cylinder(h=42,r=tap632,center=true,$fn=50);
		translate([-38,44,8]) rotate([0,90,0])cylinder(h=42,r=tap632,center=true,$fn=50);

		translate([40,47.5,15]) cube(size=[7,30,20],center=true,$fn=50);
		translate([-40,47.5,15]) cube(size=[7,30,20],center=true,$fn=50);


	}
}



module base()
{
	translate([0,17,-14.5])

	difference()
	{	
		// block
		union()
		{
			minkowski()
			{
				difference()
				{
					cube(size=[88,100,4],center=true);
					translate([0,40,0]) cube(size=[75.5,30,5],center=true);
				}
				cylinder(h=1,r=10,center=true,$fn=50);
			}
			translate([48,-17.5,10]) cube(size=[5,50,20],center=true);
			translate([-48,-17.5,10]) cube(size=[5,50,20],center=true);

			translate([48,44,15]) cube(size=[5,10,35],center=true);
			translate([-48,44,15]) cube(size=[5,10,35],center=true);
		}
		translate([0,40,0])  cylinder(h=30,r=28,center=true,$fn=50);


		// right stepper cutout
				translate([42,-17,14.5]) rotate([0,90,0]) cylinder(h=25,r=14.5,center=true,$fn=50);
				translate([42,-17,-0.5]) cube(size=[25,20,12],center=true);
		
		// left stepper cutout
				translate([-42,-17,14.5]) rotate([0,90,0]) cylinder(h=25,r=14.5,center=true,$fn=50);
				translate([-42,-17,-0.5]) cube(size=[25,20,12],center=true);

		// front 6-32 tap for steppers
				translate([0,-34.5,14.5]) rotate([0,90,0]) cylinder(h=150,r=through632,center=true,$fn=50);
		// rear 6-32 tap for steppers
				translate([0,0.5,14.5]) rotate([0,90,0]) cylinder(h=150,r=through632,center=true,$fn=50);
		// rear 6-32 tap for support
				translate([0,44,25.5]) rotate([0,90,0]) cylinder(h=150,r=through632,center=true,$fn=50);
		// holes in bottom plate

			translate([-40,33,0]) rotate([0,0,0])cylinder(h=50,r=5,center=true,$fn=50);
			translate([40,33,0]) rotate([0,0,0])cylinder(h=50,r=5,center=true,$fn=50);
	
			translate([-35,10,0]) rotate([0,0,0])cylinder(h=50,r=5,center=true,$fn=50);
			translate([35,10,0]) rotate([0,0,0])cylinder(h=50,r=5,center=true,$fn=50);
			translate([0,-10,0]) rotate([0,0,0])cylinder(h=50,r=5,center=true,$fn=50);
	
			translate([-35,-40,0]) rotate([0,0,0])cylinder(h=50,r=5,center=true,$fn=50);
			translate([35,-40,0]) rotate([0,0,0])cylinder(h=50,r=5,center=true,$fn=50);
			translate([0,-40,0]) rotate([0,0,0])cylinder(h=50,r=5,center=true,$fn=50);
	}
}

module mounted_board(rotation=0) 
{
	rotation = max(min(0, rotation), -90);
	lift = max(min(18, lift), 0);
	
	translate([0,61,11]) 
	rotate([rotation,0,0])
	translate([0,0,lift])
	union()
	{
		color("green") mirror([1,0,0]) translate([40,0,0]) cb_mount(rotation=0, lift=0);
		color("green") translate([40,0,0]) cb_mount(rotation=0, lift=0);
		circuit_board();
	}
}

module circuit_board()
{
	translate([0,-36.5,8])
	union()
	{
		translate([0,41.5,2]) qstart();
		difference()
		{
			cube(size=[85,135,2],center=true);
			for( i = [-1,1]){
				for(j=[-1,1]) {
					translate([i*36.7,j*62,0]) cylinder(h=10,r=tap632,center=true,$fn=50);
				}
			}
			for( i = [-1,1]){
				for(j=[-1,1]) {
					translate([i*34.9,j*63.8,0]) cylinder(h=10,r=tap632,center=true,$fn=50);
				}
			}
		}

	}
}

module cb_mount(rotation=0, lift=0)
{
		translate([0,0,-8])difference()
		{
			union()
			{
				cube(size=[5,10,30],center=true,$fn=50);
				translate([0,15,11])cube(size=[5,30,8],center=true,$fn=50);
				translate([-3.5,26,11]) cube(size=[12,10,8],center=true,$fn=50);
			}
		// slot
			translate([0,0,-1])cube(size=[5,2*through632,18],center=true,$fn=50);
			translate([0,0,8]) rotate([0,90,0])cylinder(h=120,r=through632,center=true,$fn=50);
			translate([0,0,-10]) rotate([0,90,0])cylinder(h=120,r=through632,center=true,$fn=50);
		// rear 6-32 tap for board
			translate([-5.2,27.3,10]) cylinder(h=15,r=tap632,center=true,$fn=50);
		}
}

module batterypack()
{
	translate([0,-7,-4]) cube([62,58,16],center=true);
}


module wheels()
{
// the additional 2mmis for the tread
	translate([61,0,8]) rotate([0,90,0]) wheel(42,6);
	translate([-61,0,8]) rotate([0,90,0]) wheel(42,6);
}


module tailwheel() 
{
	translate([0,55,7])difference()
	{
		union()
		{
			cube(size=[32,37.5,2],center=true);
			translate([0,8,-25]) rotate([0,90,0]) cylinder(h=14,r=16,center=true,$fn=50);
			translate([0,-8,-25]) rotate([0,90,0]) cylinder(h=14,r=16,center=true,$fn=50);
			translate([8,0,-25]) rotate([0,90,90]) cylinder(h=14,r=16,center=true,$fn=50);
			translate([-8,0,-25]) rotate([0,90,90]) cylinder(h=14,r=16,center=true,$fn=50);
			translate([8*.707,8*.707,-25]) rotate([0,90,-45]) cylinder(h=14,r=16,center=true,$fn=50);
			translate([8*.707,-8*.707,-25]) rotate([0,90,45]) cylinder(h=14,r=16,center=true,$fn=50);
			translate([-8*.707,8*.707,-25]) rotate([0,90,45]) cylinder(h=14,r=16,center=true,$fn=50);
			translate([-8*.707,-8*.707,-25]) rotate([0,90,-45]) cylinder(h=14,r=16,center=true,$fn=50);
		}

		translate([12,15,0]) cylinder(h=3,r=2,center=true,$fn=50);
		translate([12,-15,0]) cylinder(h=3,r=2,center=true,$fn=50);
		translate([-12,15,0]) cylinder(h=3,r=2,center=true,$fn=50);
		translate([-12,-15,0]) cylinder(h=3,r=2,center=true,$fn=50);
	}
}


module stepper_tab()
{
	difference()
		{
			union()
			{
				cylinder(h=0.8,r=3.5,center=true,$fn=50);
				translate([-3.5,0,0]) cube(size=[7,7,0.8], center=true);
			}
			cylinder(h=0.8,r=2.1,center=true,$fn=50);
		}
}

module stepper_motor()
{
	cylinder(h=19,r=14,center=true,$fn=50);
	translate([0,-13.2,0]) cube(size=[17.5,8,19],center=true);

	translate([17.5,0,9.1]) stepper_tab();
	translate([-17.5,0,9.1]) mirror([1,0,0]) stepper_tab();
}

module steppers()
{
	translate([44.5,0,0]) rotate([90,0,90]) stepper_motor();
	translate([-44.5,0,0])mirror([1,0,0])  rotate([90,0,90]) stepper_motor();
}



module spoke( spoke_rad, spoke_thick,spoke_twist)
{
	union()
	{
//		translate([spoke_rad/2,0,0]) cube(size=[spoke_rad,spoke_thick,spoke_thick], center=true);
		intersection()
		{
			translate([spoke_rad*spoke_twist,0,0])difference()
			{
					cylinder(spoke_thick,r=spoke_rad*spoke_twist,center=true,$fn=50);
					cylinder(spoke_thick,r=(spoke_rad*spoke_twist)-spoke_thick,center=true,$fn=50);
			}
			translate([spoke_rad/2,spoke_rad/2,0]) cube(size=[spoke_rad,spoke_rad,spoke_thick],center=true,$fn=50);
			cylinder(spoke_thick,r=spoke_rad,center=true,$fn=50);
		}
		
		
	}
}


module allspokes( spoke_rad, spoke_thick)
{
	union()
	{
		for( n=[0:5])
		{
			rotate([0,0,n*60]) spoke(spoke_rad-4, spoke_thick,0.6);
		}
	}
}

module wheel_disc(wheel_disc_rad, wheel_disc_thick)
{
		union()
		{	
			difference()
			{
				cylinder(h=wheel_disc_thick,r=wheel_disc_rad,center=true,$fn=200);
				cylinder(h=wheel_disc_thick,r=wheel_disc_rad-8,center=true,$fn=200);
			}
			cylinder(h=wheel_disc_thick,r=12,center=true,$fn=50);
			allspokes( wheel_disc_rad,wheel_disc_thick);

		
		}
	
}


module shaft(shaft_thick)
{
	difference()
	{
		cylinder(h=shaft_thick,r=2.5,center=true,$fn=50);
		translate([-2.5,0,0]) cube(size=[2,8,shaft_thick],center=true);
		translate([2.5,0,0]) cube(size=[2,8,shaft_thick],center=true);
	}
}


module wheel(wheel_rad, wheel_thick)
{
	difference()
	{
		wheel_disc(wheel_rad, wheel_thick);
		shaft(wheel_thick);
	}
}

