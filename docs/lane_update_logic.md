# Lane Update Logic

After the assignment/port choice is done, volume through each port is known and wait times (by hour and configuration) with current open lanes is also calculated by running DES. 

Lane update logic is run for each hour within the same "global" iteration. 

The update is done inside a "while" loop which means that as long as the conditions are true, the statements inside the loop will execute.  In reading the code below, the lanes will increment or decrement until at least one of the "while" criteria is met and code will then move on to the next "while" statement. 

The parameters below are used in the "while" condition statements - it will be important to refer back to this table as you read the rules below.  

### Parameters
| Port | Vehicle | Lane       | Minimum Wait Time | Maximum Wait Time | Minimum Allowed Lanes | Total Lanes Available at Port |
|------|---------|------------|-------------------|-------------------|-----------------------|-------------------------------|
| SY   | POV     | General    | 30                | 65                | 4                     |                               |
| SY   | POV     | Ready      | 30                | 55                | 6                     | 25                            |
| SY   | POV     | Sentri     | 5                 | 15                | 1                     |                               |
| SY   | POV     | Southbound | 5                 | 10                | 1                     | 5                             |
| OM   | POV     | General    | 35                | 50                | 2                     |                               |
| OM   | POV     | Ready      | 20                | 30                | 2                     | 13                            |
| OM   | POV     | Sentri     | 5                 | 15                | 1                     |                               |
| OM   | POV     | Southbound | 5                 | 10                | 1                     | 2                             |
| OM   | COM     | General    | 5                 | 10                | 1                     |                               |
| OM   | COM     | Fast       | 5                 | 10                | 1                     | 10                            |
| OM   | COM     | Southbound | 5                 | 10                | 1                     | 6                             |
| OME  | POV     | General    | 5                 | 20                | 2                     |                               |
| OME  | POV     | Ready      | 5                 | 20                | 2                     | 3 (or 5 or 10)                |
| OME  | POV     | Sentri     | 5                 | 15                | 1                     |                               |
| OME  | POV     | Southbound | 5                 | 10                | 1                     | 3 (or 5 or 10)                |
| OME  | COM     | General    | 5                 | 10                | 1                     |                               |
| OME  | COM     | Fast       | 5                 | 10                | 1                     | 3 (or 5 or 10)                |
| OME  | COM     | Southbound | 5                 | 10                | 1                     | 3 (or 5 or 10)                |

### Northbound POV
#### Update Sentri Lanes
* While the sentri wait time is less than the minimum wait time and open sentri lanes are greater than minimum allowed sentri lanes and northbound pov toll is equal to minimum (if do_toll option is on and is only applicable to Otay Mesa East)
    * decrease the sentri lane
    * run DES again to get updated wait time
&nbsp;

  [for example: if Sentri wait time at SY is only 2 minutes and there are 3 Sentri lanes open, close one of the lanes]

* While the sentri wait time is greater than the maximum wait time and open sentri lane is less than (maximum pov NB lanes minus minimum general lanes minus minimum ready lanes) (i.e., we can open one more sentri lane)
    * increase the sentri lane
    * run DES again to get updated wait time
&nbsp;
    
  [for example: if Sentri wait time at OM is 25 minutes and there are only 2 Sentri lanes open, open another Sentri lane]

#### Update General/Ready Lanes (General is updated and then Ready is updated)
* While the general/ready wait time is less than the minimum wait time and open general/ready lanes are greater than minimum allowed general/ready lanes and northbound pov toll is equal to minimum* (if do_toll option is on and is only applicable to Otay Mesa East)
    * if stacked lane > 0 then we change a stacked lane to regular lane, otherwise decrease the regular lane
&nbsp;

      [i.e., we first try to reduce the capacity by converting a stacked lane to a regular lane, if stacked lane is present. (if present) and then taking away a regular lane]
    * run DES again to get updated wait time

* While the general/ready wait time is greater than the maximum wait time AND open lanes are less than total available lanes or not all the open lanes are converted to stacked if open lanes are equal to total available lanes
    * if general/ready lanes (regular) are less than the (maximum pov NB lanes - sentri lanes), then increase regular lanes; otherwise increase stacked lane (if stacking is allowed)
&nbsp;

      [i.e., we first try to increase the capacity by adding a regular lane, if we cannot then we try to make one regular lane as stacked (if stacking is allowed)]
    * run DES again to get updated wait time

#### Balance General/Ready Lanes
* If new sum total of general and ready lanes comes out greater than the available total lanes (max NB POV minus sentri) then the general and ready lanes are reduced proportionaly to match the available total lanes. [i.e. we preserve Sentri total and adjust general/ready]
* Wait times for general and ready lanes are calculated again using DES
* Because the general and ready lanes have changed, the wait times may no longer be less than the maximum wait time
    * Try to convert the new open general/ready lanes to stacked lane to bring wait time below maximum wait time
* After reducing the wait times as much as possible by converting to stacked lanes, see if there is an opportunity to reduce Ready wait time further
    * While general lane wait time is less than 120 mins (max gen wait) and (1.45 * ready wait time > general wait time)
        * Give one lane from general to ready
        * Stacked and regular lanes are re-calculated using new open lanes for general and ready
        * run DES again to get updated wait time
&nbsp;

  [for example: if at SY we have 20 available lanes (25 max avaialble and 5 are sentri lanes) and based on lane allocation procedure we opened 14 General Lanes and 12 Ready lanes, there is a balancing problem. First, these lanes are reduced proportionally such that we have 9 General lanes and 11 Ready lanes, to match the total available. Next, if the General wait time is less than 2 hours and is almost the same as the Ready wait time (within 45% of ready wait time), give up a General lane so that you now have 8 General lanes and 12 FAST lanes for total of 20]
  
### Southbound POV
#### Update Southbound Lanes
* While the southbound wait time is less than the minimum wait time and open southbound lanes are greater than minimum allowed lanes and southbound pov toll is equal to minimum* (if do_toll option is on and is only applicable to Otay Mesa East)
    * decrease the southbound passenger lane
    * run DES again to get updated wait time

* While the southbound wait time is greater than the maximum wait time and open southbound lane is less than max southbound lanes
    * increase the southbound passenger lane
    * run DES again to get updated wait time

### Northbound COM
#### Update General/Fast Lanes
* While the general/fast wait time is less than the minimum wait time, open general/fast lanes are greater than minimum allowed general/fast lanes and northbound com toll is equal to minimum* (if do_toll option is on and is only applicable to Otay Mesa East)
    * decrease the lane
    * run DES again to get updated wait time

* While the general/fast wait time is greater than the maximum wait time and open general/fast lanes are less than the maximum NB COM lanes
    * increase the lane
    * run DES again to get updated wait time

#### Balance General/Fast Lanes
* If new sum total of general and fast lanes comes out greater than the available total lanes (max NB COM) then the general and fast lanes are reduced proportionally to match the available total lanes. 
* Wait times for general and fast lanes are calculated again using DES
* After reducing the lanes proportinally, see if there is an opportunity to reduce Fast wait time further
    * While general lane wait time is less than 120 mins (max gen wait) and (1.22 * fast wait time > general wait time)
        * give one lane from general to fast
        * run DES again to get updated wait time
&nbsp;

  [for example: if at OME we have 5 truck lanes total and based on lane allocation procedure we opened 3 General Lanes and 4 FAST lanes, there is a balancing problem. First, these lanes are reduced proportionally such that we have 2 General lanes and 3 FAST lanes, to match the total available. Next, if the General wait time is less than 2 hours and is almost the same as the FAST wait time (within 22% of fast wait time), give up a General lane so that you now have 1 General lanes and 4 FAST lanes for total of 5]
        
### Southbound COM
#### Update Southbound Lanes
* While the southbound wait time is less than the minimum wait time and open southbound lanes are greater than minimum allowed lanes and southbound com toll is equal to minimum* (if do_toll option is on and is only applicable to Otay Mesa East)
    * decrease the southbound commerical lane
    * run DES again to get updated wait time

* While the southbound wait time is greater than the maximum wait time and open southbound lane is less than max southbound lanes
    * increase the southbound commercial lane
    * run DES again to get updated wait time
  
&nbsp;
&nbsp;

*If the toll is higher than minimum, we don't decrease lanes, instead we decrease the toll to get more volume and increase wait time. Since the wait time is less than minimum, the purpose is to increase the wait time by either reducing the toll or reducing the capacity. 

**Stacked lanes are only allowed at San Ysidro for General and Ready traffic. 

***Increase or decrease in lanes is always by 1
