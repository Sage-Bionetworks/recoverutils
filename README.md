## recoverutils

[![GitHub R package version](https://img.shields.io/github/r-package/v/sage-bionetworks/recoverutils?label=R%20Package%20Version)](DESCRIPTION)
[![GitHub](https://img.shields.io/github/license/sage-bionetworks/recoverutils)](LICENSE.md)

This package provides functions to help with fetching data from Synapse, as well as processing, summarizing, formatting the data, and storing any output in Synapse. While this package is mainly intended for use in RECOVER, some functions in the package can be used outside this context and for general and other specific use cases.

## Requirements

-   R >= v4.0.0
-   Synapse account with relevant access permissions
-   Synapse authentication token

A Synapse authentication token is required for use of the Synapse APIs (e.g. the `synapser` package for R). For help with Synapse, Synapse APIs, Synapse authentication tokens, etc., please refer to the [Synapse documentation](https://help.synapse.org/docs/).

## Installation

Currently, `recoverutils` is not available via CRAN, so it must be installed from GitHub using the `devtools` package.

```R
install.packages("devtools")
devtools::install_github("Sage-Bionetworks/recoverutils")
```
