# Short-term survival of mallards following external transmitter attachment 

___
### Description

This repository contains the data and code used in the following publication: Short-term survival of mallards following external transmitter attachment 

Zenodo code/data DOI:  10.5281/zenodo.20613097

Manuscript DOI: 

All analyses were completed using R. See manuscript for details about analyses.

Please contact the corresponding author with questions about this data or code.
___
### Authors
Cassidy L. Waldrep (cassidy.waldrep@usask.ca; cassidywaldrep@gmail.com)
Department of Biology, University of Saskatchewan, Saskatoon, SK, Canada

Madeline A. Ward     
Department of Biology, University of Saskatchewan, Saskatoon, SK, Canada

John M. Coluccy      
Ducks Unlimited, Inc., Great Lakes/Atlantic Region, Ann Arbor, MI, USA

Nathaniel R. Huck     
Minnesota Department of Natural Resources, Brainerd, MN, USA
 
Josh C. Stiller     
New York State Department of Environmental Conservation, Albany, NY, USA

Jacob N. Straub     
SUNY Brockport, Brockport, NY, USA

Nathaniel R. Huck    
Pennsylvania Game Commission, Harrisburg, PA, USA

Ted S. Barney     
Canadian Wildlife Service, Environment and Climate Change Canada, Sackville, NB, Canada

Abigail C. Butler  
SUNY Brockport, Brockport, NY, USA

Austin H. Damminger  
New Jersey Fish and Wildlife, Woodbine, NJ, USA

Shawn W. Meyer     
Canadian Wildlife Service, Environment and Climate Change Canada, Ottawa, ON, Canada

Theodore C. Nichols    
New Jersey Fish and Wildlife, Woodbine, NJ, USA

Daria J. Sparks     
Virginia Department of Wildlife Resources, Charles City, VA

Mathieu Tétreault       
Canadian Wildlife Service, Environment and Climate Change Canada, Québec, QC, Canada

Mitch D. Weegman       
Department of Biology, University of Saskatchewan, Saskatoon, SK, Canada


___
### Files

- `nimblemodeldata_apr2026.csv`:  All data for the known fate logistic regression model (max 15 days per bird)
- `known_fate_bandingmortality_model.R`: includes nimble model code for known fate logisitic regression model

### Data column names
- bandnum_index: ID value for each bird (1256 total birds)
- bander_index: ID value associated with a specific bander
- day_index: 0-15, 0 being the day of banding and the rest are the following calendar days
- age_index: 1 (ASY birds), 2 (SY birds)
- state_index: state or province index (total of 17 different agencies)
- mean_mintemp_prev5_scaled: the 5 day minimum temperature rolling average, scaled
- PCA_weight_scaled: adjusted body weight based on PCA analysis (see methods for description)
- interval: days since last check in (majority of birds missed no checkins) for known fate model
- survived: 0 being the bird died that day, 1 being the bird lived
