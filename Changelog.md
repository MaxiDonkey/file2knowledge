#### 2025, June 4 versio 1.0.1
- Update the DelphiGenAI documentation.

#### 2025, May 27 version 1.0.1
- Fix “No mapping for the Unicode character exists in the target multi-byte code page.” <br > 
For the `v1/responses` endpoint, buffer the incoming chunks and process them only once they’re fully received to avoid the error. <br> 
Refer to DelphiGenAI
