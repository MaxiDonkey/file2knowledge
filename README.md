# File2Knowledge
![Delphi Next Gen Ready](https://img.shields.io/badge/Delphi--Next--Gen-ready-brightgreen)
![GitHub](https://img.shields.io/badge/IDE%20Version-Delphi%2012-yellow)
![GitHub](https://img.shields.io/badge/Updated%20on%20June%2014,%202025-blue)

Mini-lab Delphi/VCL open source to experiment with the `v1/responses endpoint` of the OpenAI API in a modern environment. 
Clone & run: the app acts as a tutor for exploring my AI wrappers through the `file_search`, `embeddings`, and `chat` features.

## Changelog

To review the latest changes, please refer to the [changelog](https://github.com/MaxiDonkey/file2knowledge/blob/main/Changelog.md).

>[!IMPORTANT]
> To perform the update, install [DelphiGenAI](https://github.com/MaxiDonkey/DelphiGenAI) version 1.1.0 and then recompile the project.

## Introduction

> **Built with Delphi 12 Community Edition**  
> You can compile and test this app **free of charge (no purchase, no lock-in)**  
> as long as you meet the Delphi CE licence terms  
> *(≤ USD 5 000 annual revenue or funding, up to five developers, renewable yearly).*  
> See the full [Delphi CE FAQ](https://www.embarcadero.com/products/delphi/starter/faq).
>
> *Delphi* and the Delphi logo are trademarks of Embarcadero Technologies.  
> Their mention here is purely descriptive and does **not** imply endorsement.

File2knowledge was designed to provide a concrete implementation of the OpenAI API’s `v1/responses endpoint` (necessary for the agentic approach).
Its main goal: to demonstrate how to leverage advanced file search (file_search) features and the use of vector stores to enhance the semantic processing of documents.
This approach enables more contextual, relevant, and intelligent responses when querying technical documentation, source code, or any other textual files.

![Preview](https://github.com/MaxiDonkey/file2knowledge/blob/main/Images/F2KAni.gif?raw=true "Preview")

## Quick Start

```bash
git clone https://github.com/MaxiDonkey/file2Knowledge.git
```
open WrapperAssistant.dproj     # Delphi 12 Athens
Prerequisites: OpenAI API key

## Dependencies
- Add [DelphiGenAI (OpenAI wrapper)](https://github.com/MaxiDonkey/DelphiGenAI) version 1.1.0 to your Delphi project **Library Path** if not globally referenced
- Delphi 12 Athens (or later)
- WebView2 Runtime (EdgeView2 for VCL)
- OpenAI API key (OPENAI_API_KEY)
- Windows 11 MineShaft (custom VCL theme)

![Preview](https://github.com/MaxiDonkey/SynkFlowAI/blob/main/Images/themis.png?raw=true "Preview")

## Things You Should Know



>[!NOTE]
> Make sure to correctly set the **search path** to the `DelphiGenAI` wrapper in your Delphi project settings. This is required for proper compilation and integration.

![Preview](https://github.com/MaxiDonkey/file2knowledge/blob/main/Images/Genai_path.png?raw=true "Preview")

>Before running the client for the first time, make sure to place the appropriate DLL (32-bit or 64-bit) in the executable's directory. The required files are available in the repository.

>[!WARNING]
>To access reasoning visualization with o-models, you must enable this feature in the Verification section of your [OpenAI account](https://platform.openai.com/settings/organization/general). The activation process takes only a few minutes.

>[!NOTE]
>To access the uploaded files and active vector stores, go to the [dashboard](https://platform.openai.com/logs) then navigating to the `Storage` section.

## Features

- Upload .txt / .md → embeddings auto, Vector search handled by OpenAI

- Persistent multi-turn chat (session history preserved)

- JS-style Promises (TPromise<T>) and generalized IoC

- UI VCL & WebView2

- Session-based conversational chaining with OpenAI response IDs

- Web research and reasoning.

## License

This project is licensed under the [MIT](https://choosealicense.com/licenses/mit/) License.

## Going further

**Want the full architecture breakdown?**  

[Read the deep-dive.md](https://github.com/MaxiDonkey/file2knowledge/blob/main/deep-dive.md)
