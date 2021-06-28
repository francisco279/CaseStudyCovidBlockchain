/**
* Name: Application
* Based on the internal empty template. 
* Author: Francisco Aleman, Gamaliel Palomo, and Mario Siller
* Tags: 
*/

model Application

/* Insert your model definition here */
global{
	
	//variable that activates the sending of data to the python server
	int send_message_activator 	<- 0; 
	int send_message_activator2 <- 0;
	int virtual_tokens 			<- 0;
	int applied_virtual_tokens 	<- 0;
	int applied_vaccines 		<- 0;
	int num 					<- 0;
	bool remove_people 			<- true; //estaba en true
	int count_remove 			<- 0;
	bool enable_remove 			<- false;
	bool corr 					<- false;
	//bool enable_applications 	<- false; //variable that triggers when people store their qr on blockchain and can get vaccinated
	//bool next_people            <- true;//variable that triggers when the next people need to register on the blockchain
	bool qr						<- true;//variable that triggers the sending of qr data
	bool enable_qr				<- false;
	
	
	int count_applications 		<- 0;
	int nb_applications 		<- 0; //estaba en el manager
	
	int Number_transactions 	<- 0; //variable to update number of transactions
	int received_transactions 	<- 0;//variable to update the number of transactions received in the python server
	int ethereum_transactions 	<- 0;//variable to update the number of successful ethereum transactions
	list<people> people_priority_1 			<- nil update:people where(each.priority = 1);
	//Activar solo para pre registro
	//list<people> people_pre_registration 	<- nil update:people where(each.pre_registered = false);
	list<people> pruebas;
	
	bool enable_sending_data 	<- false;
	bool save_to_csv 			<- false;
	int timeElapsed <- 0 update: int(cycle*step);
	
	
	string case_study 	<- "Guadalajara/small" among:["Guadalajara/small","Guadalajara/big","Tlaquepaque"];
	string scenario 	<- "default";
	file blocks_file 	<- file("../includes/"+case_study+"/blocks.shp");//apple files
	file streets_file 	<- file("../includes/"+case_study+"/roads.shp"); //streets_file files
	
	geometry shape 					<- envelope(streets_file);//Ambient take the form of the streets_file file
	graph roads_network; 					//We declare a street graph
	map<string,rgb> people_color 	<- ["infected"::#red,"immune"::#gray, "vaccinated"::#green]; //map colors with status
	
	init{
		create block from:blocks_file with:[cvegeo::string(read("CVEGEO")),pob_60_mas::int(read("P_60YMAS"))]; //we create the block agent
		create street from:streets_file; 						//We create the street agent
		roads_network <- as_edge_graph(street);	//We create a graph with the agent street
		
		
		//UDP server to receive confirmations of successful ethereum transactions
		create UDP_Server1 number:1{
			if enable_sending_data{
				do connect to: "localhost" protocol: "udp_server" port: 9875 ;
			} 
		}
		
		//Servidor que recibe los tokens virtuales y tokens virtuales aplicados
		create UDP_Server2 number:1{
			if enable_sending_data{
				do connect to: "localhost" protocol: "udp_server" port: 9876;
			}
		}
		////UDP server to receive transaction confirmations received from the python server
		create UDP_Server number:1{
			if enable_sending_data{
				do connect to: "localhost" protocol: "udp_server" port: 9877 ;
			}
		}
		
		create UDP_Server_Registered number:1{
			if enable_sending_data{
				do connect to: "localhost" protocol: "udp_server" port: 9878 ;
			}
		}
		
		//TCP Client to send data to smart contracts 
		create TCP_Client number:1{
			if enable_sending_data{
				do connect to: "localhost" protocol: "tcp_client" port: 9999 with_name: "Client";	
			}
		}
		
		
		ask block{
			create people number:int(pob_60_mas/10){
				self.home 				<- any_location_in(myself.shape);
				self.location 			<- home;
				self.age 				<- rnd(61,100);
				self.target 			<- home;
				self.curp        		<- self.name + "curp";
				self.phone          	<- "8711152690";
				//self.pre_registered     <- false;
				do update_priority;
			}
		}
		
		create people number:50{
			self.home 			<- any_location_in(one_of(block));
			self.location 		<- home;
			self.age 			<- rnd(18,60);
			self.target 		<- home;
			//self.pre_registered <- true;
			self.curp			<- self.name + "curp";
		} 
		create vaccination_point {
			physical_tokens <- length(people);
			write physical_tokens;
		}
		ask vaccination_point{
			create manager{
				location 		<- myself.location;
				assigned_to 	<- myself;
			}
		}
		
		step <- 5#minute;
	}
	
	
	//reflex save_data when:save_to_csv and activador=true{//activador = true{
	bool activador <- false;
	reflex save_data when:activador=true{//activador = true{
		
		write "Estoy en el save data";
		int physical_token_counter;
		
		ask vaccination_point{
			physical_token_counter 	<- physical_tokens;
			applied_vaccines 		<- length(people) - physical_tokens;
		}
		
		string data <- ""+cycle+","+int(timeElapsed/86400)+","+physical_token_counter+","
			+virtual_tokens+","+applied_vaccines+","+applied_virtual_tokens+","+
			length(people where(each.age > 59 and each.status="vaccinated"))+","+
			length(people where(each.age<60 and each.status ="vaccinated"))+","+nb_applications;
		save data to:"../output/results_"+scenario+".csv" type:csv rewrite:false;
		activador <- false;
			
	}
	
	reflex save_without_blockchain when: every(1#day) and enable_sending_data = false{
		write "Estoy en el save data";
		int physical_token_counter;
		
		ask vaccination_point{
			physical_token_counter 	<- physical_tokens;
			applied_vaccines 		<- length(people) - physical_tokens;
		}
		
		string data <- ""+cycle+","+int(timeElapsed/86400)+","+physical_token_counter+","
			+virtual_tokens+","+applied_vaccines+","+applied_virtual_tokens+","+
			length(people where(each.age > 59 and each.status="vaccinated"))+","+
			length(people where(each.age<60 and each.status ="vaccinated"))+","+nb_applications;
		save data to:"../output/results_"+scenario+".csv" type:csv rewrite:false;
		
	}
	
	//
	reflex newday when:int(timeElapsed/86400) > 8 and every(1#day){
		send_message_activator 	<- 0;
		write "Requesting..";
		string msg <- "request2";
		if enable_sending_data{
			ask TCP_Client{
				data <- msg;
				do send_message;
			}
		}
	}	
	
	
	//HABILITAR SOLO SI SE DESEA REGISTRAR A LAS PERSONAS
	//reflex record_pre_registration when:not empty(people_pre_registration){
		//if next_people{
			//do pre_application(people_pre_registration[0]);
			
			//ask people_pre_registration[0]{
				//pre_registered <- true;
			//}
			//remove index:0 from:people_pre_registration;
			//next_people <- false;
		//}
		
		//if empty(people_pre_registration){
			//enable_applications <- true;
			//write "ya soy true";
		//}
	//}
	
	string save_pre_aplication(people the_person){
		if the_person.priority = 1{
			return "preRegistro" + " " + "3" + " " + the_person.name + " " + the_person.curp + " " + the_person.phone;	
		}
	}
	
	//Send data of vaccine application
	action pre_application(people the_person){
		string mydata <- save_pre_aplication(the_person);
		if enable_sending_data{
			ask TCP_Client{
				data 					<- mydata;
				do send_message;
				send_message_activator 	<-0;
			}
		}
	}
}

//***************************** ROADS AGENT *************************************
species street{
	aspect basic{ //Street aspect
		draw shape color:#black;
	}
	aspect gray{
		draw shape color:#gray;
	}
}

//****************************** BLOCK AGENT ************************************
species block{ 
	string cvegeo;
	int pob_60_mas;
	aspect basic{ //Block aspect
		draw shape color:rgb (26, 82, 119,80);
	}
	aspect pob_60_mas{
		draw shape color:rgb(
			int((pob_60_mas/100)*255),
			0,
			0,
			0.5		
		) border:rgb(200,200,200,0.5);
	}
}

species vaccination_point{
	
	block belongs_to;
	
	//Physical token variables
	int physical_tokens <- 0;
	int used_tokens <- 0;
	
	int applications_per_day 	    <- int(length(people)/10);
	list<people> vaccination_queue 	<- [];
	init{
		belongs_to 		<- one_of(block where(each.cvegeo = "1403900012183008"));
		shape 			<- belongs_to.shape;
	}
	
	reflex daily_update{
		used_tokens <- length(people) - physical_tokens;
	}
	 
	
	action register_person(people the_person){
		add the_person to:vaccination_queue;
	}  
	aspect basic{
		draw shape color:#darkviolet;
	}
}

//************************************ VACCINE MANAGER AGENT ***************************************************
species manager{
	float honesty;
	float motivation;
	float risk_aversion;
	float reward;
	vaccination_point assigned_to;
	
	
	
	init{
		honesty 			<- float(rnd(100))/100;
		risk_aversion 		<- float(rnd(100))/100;
		reward 				<- float(rnd(100))/100;
	}
	
	float compute_motivation{
		//Probabilidad de cometer un acto de corrupción
		float result <- 0.0;
		return result;
	}
	
	//reflex to evaluate which agent person to vaccinate and send the data to the python server
	reflex call_for_vaccination when: every(1#day){
		if length(people_priority_1) > assigned_to.applications_per_day{
			int index <- 0;
			loop times:assigned_to.applications_per_day{
				people current_person <- people_priority_1[index];
				ask current_person{
					do update_target(myself.assigned_to);//Diciendo a la persona que se dirija a este punto de vac.
				}
				index <- index + 1;
			}
		}
		else{
			int counter 	<- length(people_priority_1);
			int index 		<- 0;
			loop times:counter{
				people current_person <- people_priority_1[index];
				ask current_person{
					do update_target(myself.assigned_to);//Diciendo a la persona que se dirija a este punto de vac.
				}
				index <- index + 1;
			}
		}
	}
	
	
reflex search_qr when:not empty(assigned_to.vaccination_queue){
	
		//Busca si existe el agente persona esta almacenado en Blockchain
		if qr = true and enable_qr = true{
			write "Buscando QR"; 
			do qr_data(assigned_to.vaccination_queue[0]);
			qr <- false;
		}else if remove_people = true and enable_qr = false{
			write "No buscando QR";
			do application_data(assigned_to.vaccination_queue[0]);
			ask assigned_to.vaccination_queue[0]{
				status 					<- "vaccinated";
				last_change 			<- cycle;
				registered 				<- false;
				target 					<- self.home;
				immunity 				<- true;
				do update_priority;
			}
			
			assigned_to.physical_tokens <- assigned_to.physical_tokens - 1; //Restar 1 token físico cada que se aplica una vacuna
			nb_applications  <- nb_applications + 1;
			remove index:0 from:assigned_to.vaccination_queue;
			remove_people    <- false;
			if enable_sending_data = false{
				remove_people	<- true;
			}
			
 		}
		
}

	bool request <- false;
	
	reflex activate_request when:count_applications = assigned_to.applications_per_day{
		count_applications <- 0;
		request <- true;
		if request{
			write "send";
			string msg <- "request";
			if enable_sending_data{
				ask TCP_Client{
					data <- msg;
					do send_message;
				}	
			}
			request <- false;
			send_message_activator <- 0;
		}

	}
	
	reflex last_request when:int(timeElapsed/86400) > 7 and count_applications = 35{
		count_applications <- 0;
		request <- true;
		if request{
			write "send";
			string msg <- "request";
			if enable_sending_data{
				ask TCP_Client{
					data <- msg;
					do send_message;
				}	
			}
			request   <- false;
			send_message_activator <- 0;
		}

	}
//------------------------------------------------------------ENVIA DATOS DE LAS PERSONAS VACUNADAS-----------------------------
	//Send data when a vaccine is aplicated
	string aplication_vaccine(people the_person){
		int date_application <- 2015;
		
		if the_person.priority = 1{
			return "Aplicar" + " " + string(date_application) + " " + string(the_person.age) + " " + the_person.morbidity;	
		} else if the_person.priority != 1{
			return "priority2";
		}
		
		
	}
	
	//Send data of vaccine application
	action application_data(people the_person){
		string mydata <- aplication_vaccine(the_person);
		if enable_sending_data{
			ask TCP_Client{
				data <- mydata;
				do send_message;
				send_message_activator <-0;
			}
		}
	}
//--------------------------------------------------------ENVIA DATOS PARA SOLICITAR LA INFORMACION DEL QR-------------------------

	string qr_people(people the_person){
			if the_person.priority = 1{
				return "QR" + " " + the_person.curp;	
			}else if the_person.priority != 1{
				return "QR" + " " + the_person.curp;
			}
	}
	
	//Send data of vaccine application
	action qr_data(people the_person){
		string mydata <- qr_people(the_person);
		if enable_sending_data{
			ask TCP_Client{
				data <- mydata;
				do send_message;
				send_message_activator <-0;
			}
		}
	}
	aspect default{
		draw circle(5) color:rgb (210, 115, 203,255);
	}
}

//************************************ PEOPLE AGENT ***************************************************
species people skills:[moving]{
	point home;
	point target; //target that the people follows
	path path_to_follow;//path that the epeople follows
	string status 		<- "susceptible" among:["susceptible","infected","immune", "vaccinated"];
	int age; //People's age
	bool morbidity; //Morbidity of the people
	float inmunity_time <- 0#days; //time of infection of the people
	int priority; //priority of the person to receive the vaccine
	//string message1 <- "";
	//bool m <- false;
	string curp;
	string phone;
	bool pre_registered;
	
	
	//Agenda related variables
	bool immunity 	<- false;
	bool to_vaccinate <- false;
	bool registered <- false;
	int last_change;
	vaccination_point vp; //Punto de vacunación que le corresponde
	
	init{
		morbidity 		<- flip(0.5);
		last_change 	<- cycle;
	}
	
	action update_target(vaccination_point tgt){
		vp 		<- tgt;
		target 	<- any_location_in(vp);
		//do update_path;
	}	
	
	action update_priority{
		priority <-  (not immunity and age>59)?1:2;
		//priority <- inmunity_time>4#months?1:2;
	}
	
	reflex movement when:target != location{
		do goto target:target;
		//do follow path: path_to_follow;
	}
	
	reflex arrive when:target=location and location!=home{
		if not registered{
			ask vp{
				do register_person(myself);//Al llegar, la persona se registra
				myself.registered <- true;
			}
		}
	}
	
	reflex corruption when:every(1#day) and priority != 1 and flip(0.01) and not immunity and target=location and corr{
		//Ir a vacunarme sin ser llamado.
		do update_target(vaccination_point closest_to self);
	}
	

	action update_path{
		path_to_follow 		<- nil;
		path_to_follow 		<- path_between(roads_network,location,target);
		loop while: path_to_follow = nil{
			write name;
			do wander speed:5.0;
			target 			<- any_location_in(vp);
			path_to_follow 	<- path_between(roads_network,location,target);
		}		
	}
	
	aspect basic{
		draw circle(10) color:self.age>=60?people_color[status]:(status="vaccinated"?#red:#blue);//people's aspect according to their status
		//draw string(morbidity) color:#black;
		//draw string(age) color:#black;
	}
}

//************************************ TCP CLIENT (SEND DATA TO PYTHON [SMART CONTRACT IN BLOCKCHAIN]) ***********************************

species TCP_Client skills:[network]{
	string data; //Data to send to blockchain

	//action to send message
	action send_message{
		if send_message_activator = 0{
			string mm <- data;
			do send contents: mm;
			send_message_activator <- 1;
		}
	}
}



//****************************************UDP SERVERS***************************************

//UDP server that receives the confirmation of the transactions received in the python server
//Transacciones recibidas en el servidor python
species UDP_Server skills: [network]
{
	reflex fetch when:has_more_message() {	
		loop while:has_more_message() and enable_sending_data
		{
			message s 			<- fetch_message();
			string transactions <- string(s.contents);
			write transactions;
			
			if transactions contains "priority1"{
				count_applications 		<- count_applications + 1;
				remove_people			<- true;
				qr						<- true;
				write "prioridad 1";
			}else if transactions contains "priority2"{
				remove_people			<- true;
				write "prioridad 2";
			}
		}
	}
}



//UDP server that receives the confirmation of successful ethereum transactions
//Transacciones exitosas (Vacunas aplicadas)
species UDP_Server1 skills: [network]
{
	reflex fetch when:has_more_message() {	
		loop while:has_more_message() and enable_sending_data
		{
			message s <- fetch_message();
			string transactions <- string(s.contents);
			write transactions;
			//next_people es para habilitar la siguiente persona que debe ser registrada
			//next_people <- true;
		}
	}
}

species UDP_Server_Registered skills: [network]
{
	
	
	reflex fetch when:has_more_message() {	
		loop while:has_more_message() and enable_sending_data
		{
			message s 				<- fetch_message();
			string transactions		<- string(s.contents);
			write transactions;
			
			if transactions  contains "notregistered"{
				do not_apply_vaccine;
			}
			else if transactions  contains "registered"{
				do apply_vaccine_registered;
			}
		
		}
	}
	
	action not_apply_vaccine{
		ask manager{
			
			ask assigned_to.vaccination_queue[0]{
				target 		<- self.home;
			}
			remove index:0 from:assigned_to.vaccination_queue;
			remove_people 	<- true;
			qr				<- true;
		}
	}
	
	action apply_vaccine_registered{
		ask manager{
			if remove_people{
				do application_data(assigned_to.vaccination_queue[0]);
				ask assigned_to.vaccination_queue[0]{
					status 					<- "vaccinated";
					last_change 			<- cycle;
					registered 				<- false;
					target 					<- self.home;
					immunity 				<- true;
					do update_priority;
			}
			
			assigned_to.physical_tokens <- assigned_to.physical_tokens - 1; //Restar 1 token físico cada que se aplica una vacuna
			nb_applications  	<- nb_applications + 1;
			remove index:0 from:assigned_to.vaccination_queue;
			remove_people    <- false;
			}
		}
	}
 }
	


//Servidor para recibir los tokens virtuales y los tokens virtuales aplicados
species UDP_Server2 skills: [network]
{
	int num2 <-0;
	reflex fetch when:has_more_message() and enable_sending_data {	
		loop while:has_more_message()
		{
			message s <- fetch_message();
			string transactions <- string(s.contents);
			write transactions;
			if num2 = 0{
				virtual_tokens <- int(transactions);
				write "virtual token" + " "+  virtual_tokens;
				num2 <- num2 + 1;
			}else if num2 = 1{
				applied_virtual_tokens <- int(transactions);
				write "applied virtual token" + " " +applied_virtual_tokens;
				activador <- true;
				num2 <- 0;
			}
			//num2 <- num2 + 1;
			write num2;
		}
	}
}




