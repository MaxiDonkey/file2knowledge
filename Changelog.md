#### 2025, November 1 version 1.0.8
- Fix the date sorting when arranging the session list.
- Code optimization for the DeepResearch function.


#### 2025, November 1 version 1.0.7
- Upgrade to DelphiGenAI wrapper version 1.3.1
  - Added support for o3-deep-research, o4-mini-deep-research models for Deep Research.
  - Implementation of the methods enabling Deep Research execution whenever one of the two newly added models is selected from the list of available search execution models. 
- Data update including DelphiGenAI version 1.3.1
- Data update including File2knowledge version 1.0.7

<br>

#### 2025, August 15 version 1.0.6
- Upgrade to DelphiGenAI wrapper version 1.2.1
  - Added support for GPT-5 series models (mini, nano) for search and reasoning features.
  - Introduced the `verbosity` parameter to configure the response detail level for GPT-5 models.
  - Upgrade streaming events in the `Provider.OpenAI.StreamEvents` unit
- Data update including DelphiGenAI version 1.2.1

<br>

#### 2025, August 2 version 1.0.5
- Data update including DelphiMistralAI version 1.3.0

<br>

#### 2025, June 14 version 1.0.4
- Integrate GenAI v1.1.0 and optimize unit methods in the `Providers` directory.
- Manager.Async.Promise replaced by GenAI.Async.Promise from GenAI wrapper.

<br>

#### 2025, June 4 version 1.0.1
- Update the DelphiGenAI documentation.

<br>

#### 2025, May 27 version 1.0.1
- Fix “No mapping for the Unicode character exists in the target multi-byte code page.” <br > 
For the `v1/responses` endpoint, buffer the incoming chunks and process them only once they’re fully received to avoid the error. <br> 
Refer to DelphiGenAI
