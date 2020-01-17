# Port Choice Workplan

## Background
Caltrans and San Diego are exploring the feasibility of a new port of entry east of Otay Mesa. They are interested in understanding the demand at the new port, including willingness to pay. WSP adapted a model created by HDR that estimated these quantities. The model used network assignment to inform the port of entry choice. The network assignment model is not working as expected and takes a long time to run. So we are going to replace it with a port of entry choice model. 

## Workplan

### Port Choice Model
A multi-nomial logit model with three choices: San Ysidro, Otay Mesa, and Otay Mesa East. Probabilities for each of the ports are computed for each origin-destination pair for each hour of the day. 

#### Specification
The variables in the port of entry choice model are as follows:
* time from origin to the port of entry;
* time from port of entry to destination;
* time in queue/processing at port of entry;
* cost to pass through the port, i.e., Otay Mesa East.

We will use the SANDAG ABM port of entry choice model if it uses variables that we have on hand.  

Outputs of the model are as follows:
* trip tables segmented by vehicle class (i.e., personal, commercial), traveler class (e.g., general,  ready, SENTRI), and port of entry (i.e., San Ysidro, Otay Mesa, Otay Mesa East);
* delays by vehicle class and traveler class by port of entry (from the discrete events simulation).

Debug output:
* level-of-service variables and utility calculations for specified origin-destination pair. 

#### Software
* Assignment: TransCAD
* Skimming: TransCAD
* Port of entry choice: R
* Discrete events simulation: R
* Data exchange: CSV

### Skimming
The following changes to the skimming procedures are needed to implement the port choice model:
* Create zone centroids at each of the three ports of entry (San Ysidro, Otay Mesa, and Otay Mesa East);
* Connect the above zone centroids to the network with centroid connectors, on either side of the border;
* Develop skimming procedures for each hour of the day.

### Assignment
The following changes to the assignment procedures are needed to implement the port choice model:
* Start with the existing assignment classes;
* Segment each existing class into three, port-of-entry-specific classes, where links for the other ports of entry are removed

### Model Flow
The following changes to the model flow/steps are needed:
* Introduce initial port of entry delay and toll values for each port;
* Outer iteration loop:
	* Assignment;
	* Skims;
	* Inner iteration loop:
		* Port of entry choice model;
		* Discrete event simulation model;
* Inner iteration convergence: successively similar discrete event simulation results;
* Outer iteration convergence: successively similar skims. 
