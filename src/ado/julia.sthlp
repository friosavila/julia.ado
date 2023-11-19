{smcl}
{* *! julia 0.5.1 19 November 2023}{...}
{help julia:julia}
{hline}{...}

{title:Title}

{pstd}
Bridge to Julia{p_end}

{title:Syntax}

{phang}
{cmd:julia}[, {cmdab:qui:etly}]: {it:juliaexpr}

{phang2}
where {it:juliaexpr} is an expression to be evaluated in Julia.

{phang}
{cmd:julia} {it:subcommand} [{varlist}], [{it:options}]

{synoptset 24 tabbed}{...}
{synopthdr:subcommand}
{synoptline}
{synopt:{opt PutVarsToDF}}Copy Stata variables to Julia DataFrame, mapping missing to NaN{p_end}
{synopt:{opt PutVarsToDFNoMissing}}Copy Stata variables to Julia DataFrame; no special handling of missings.{p_end}
{synopt:{opt PutVarsToMat}}Copy Stata variables to Julia matrix, mapping missing to NaN{p_end}
{synopt:{opt PutVarsToDFNoMissing}}Copy Stata variables to Julia matrix; no special handling of missings.{p_end}
{synopt:{opt GetVarsFromDF}}Copy Stata variables from Julia DataFrame, mapping NaN to missing{p_end}
{synopt:{opt GetVarsFromMat}}Copy Stata variables from Julia matrix, mapping NaN to missing{p_end}
{synopt:{opt PutMatToMat}}Copy Stata matrix to Julia matrix, mapping missing to NaN{p_end}
{synopt:{opt GetMatFromMat}}Copy Stata matrix from Julia matrix, mapping NaN to missing{p_end}
{synopt:{opt AddPkg}}Install Julia packages if not already installed{p_end}
{synopt:{opt UpPkg}}Update Julia packages{p_end}
{synoptline}
{p2colreset}{...}

{phang}
{cmd:julia PutVarsToDF} [{varlist}] {ifin}, [{opt dest:ination(string)} {opt cols(string)}]

{phang}
{cmd:julia PutVarsToDFNoMissing} [{varlist}] {ifin}, [{opt cols(string)} {opt dest:ination(string)}]

{phang}
{cmd:julia PutVarsToMat} [{varlist}] {ifin}, [{opt dest:ination(string)}]

{phang}
{cmd:julia PutVarsToMatNoMissing} [{varlist}] {ifin}, [{opt dest:ination(string)}]

{phang}
{cmd:julia GetVarsFromDF} {varlist} {ifin}, [{opt cols(string)} {opt source({varlist})} {opt replace}]

{phang}
{cmd:julia GetVarsFromMat} {varlist} {ifin}, [{opt source(string)}]

{phang}
{cmd:julia PutMatToMat} {it:matname}, [{opt dest:ination(string)}]

{phang}
{cmd:julia GetMatFromMat} {it:matname}, [{opt source(string)}]

{phang}
{cmd:julia AddPkg} {it:namelist}

{phang}
{cmd:julia UpPkg} {it:namelist}


{marker description}{...}
{title:Description}

{pstd}
{cmd:julia} gives access from the Stata prompt to the free programming language Julia. It provides three
sorts of tools:

{p 4 7 0}
1. The {cmd:julia:} prefix command, which allows you to send commands to Julia and see the results. Example: {cmd:julia: 1+1}.

{p 4 7 0}
2. Subcommands, listed above, for high-speed copying of data between Julia and Stata, as well as for installation of Julia packages.

{p 4 7 0}
3. An automatically loaded library of Julia functions to allow reading and writing of Stata variables, macros, matrices, and scalars. These
functions hew closely to those in the {browse "https://www.stata.com/plugins":Stata Plugin Interface}. For example,
{cmd:julia: SF_macro_save("a", "3")} is equivalent to {cmd:global a 3}.

{pstd}
Because Julia does just-in-time-compilation, sometimes commands take longer on first use. In particular, if you have not installed
the DataFrames.jl package in Julia, {cmd:julia} will attempt to do so on first use, and that can take a minute or so.

{pstd}
The {cmd:julia:} prefix only accepts single-line expressions. But in a .do or .ado file, you can stretch that limit:{p_end}
{pmore}{inp} julia: local s = 0; for i in 1:10 s += i end; s {p_end}

{pmore}{inp} julia: {space 11}/// {p_end}
{pmore}{inp} {space 4}local s = 0; {space 1}/// {p_end}
{pmore}{inp} {space 4}for i in 1:10 /// {p_end}
{pmore}{inp} {space 8}s += i {space 3}/// {p_end}
{pmore}{inp} {space 4}end; {space 9}/// {p_end}
{pmore}{inp} {space 4}s{p_end}

{pstd}
The data-copying subcommands are low-level and high-performance. On the Stata side, they interact with
the {browse "https://www.stata.com/plugins":Stata Plugin Interface} (SPI). Their minimalist design
has two important implications for users.

{pstd}
First, when copying from Stata to Julia, all numeric data, whether stored as {cmd:byte}, {cmd:int}, 
{cmd:long}, {cmd:float}, or {cmd:double}, is converted
to {cmd:double}--{cmd:Float64} in Julia--beacuse that is how the SPI provides the values. 

{pstd}
Second, the routines do not work (properly) with Julia {cmd:missing}. In Julia, {cmd:NaN}
is a special floating-point value. Stata also represents missing with special floating
point values. But in Julia, DataFrame columns with potentially missing values are stored in a more complex 
way (vectors of a Union type). {cmd:missing} is the sole instance of the data type, 
{cmd:Missing}. For speed, the {cmd:julia} subcommands ignore that complexity. PutVarsToDF maps Stata
missing to NaN, not {cmd:missing}, so that destintation columns are pure vectors of 
{cmd:Float64}. PutVarsToDFNoMissing is even lazier (and faster): it maps Stata missings to 
the same special floating-point values in Julia that they already have in Stata, which is approximately 
8.98847e307. So PutVarsToDFNoMissing is most appropriate when it is known that there are no missings
in the data to be copied.

{pstd}
Similarly, GetVarsFromDF maps Julia NaN to Stata missing. GetVarsFromDFNoMissing 
makes no effort to recode Julia NaNs; however, NaN appears to map to Stata missing anyway for Stata 
destination variables of type other than {cmd:double}. Both of these subcommands will map Julia 
{cmd:missing} to indeterminate values.

{pstd}
To recode Julia NaN's to {cmd:missing} after copying Stata variables to a new DataFrame {cmd:df}, one
can type {cmd:julia: allowmissing!(df)} to make the DataFrame capable of holding {cmd:missing} and
then {cmd:julia: replace!.(eachcol(df), NaN=>missing)}. In the reverse direction, before copying back to Stata, 
one should type {cmd:julia: replace!.(eachcol(df), missing=>NaN)}.


{title:Options}

{pstd}
{cmd:julia,} {opt qui:etly}{cmd::...} is nearly the same as {cmd:quietly julia:...}. The difference
is that the first will stop the software from copying the output of a Julia command to Stata before suppressing
that output. This will save time if the output is, say, the contents of a million-element vector.

{pstd}
In the data-copying subcommands, the {varlist}'s and {opt matname}'s before the commas always
refer to Stata variables or matrices. If a {varlist} is omitted where it is optional,
the variable list will default to {cmd:*}, i.e., all variables in the current data frame in 
their current order.

{pstd}
The options after the comma in these subcommands refer Julia objects. {opt dest:ination()}
and {opt source()} name the Julia matrix or DataFrame to be written to or from. When
a DataFrame name is not provided, it defaults to {cmd:df}. The {opt cols()} option specifies the 
DataFrame columns to be copied to or from. It defaults to the Stata {varlist} before the comma.

{pstd}
Destination Stata matrices and Julia matrices and DataFrames are entirely replaced. Destination Stata
variables will be created with type double or, if {opt replace} is specified, overwritten, subject to any
{ifin} restriction.


{title:Stored results}

{pstd}
{cmd:julia:}, without the {opt qui:etly} option, stores the output in the macro {cmd:r(ans)}.


{title:Stata interface functions}

{pstd}
The {cmd:julia.ado} package includes, and automatically loads, a Julia module that gives access to the 
{browse "https://www.stata.com/plugins":Stata Plugin Interface}, which see for more information on 
syntax. The functions in module allow one to read and write
Stata objects from Julia. The major departure in syntax in these Julia versions is that the functions
that return data, such as an element of a Stata matrix, do so through the return value rather than a
supplied pointer to a pre-allocated storage location. For example, {cmd:julia: SF_scal_use("X")}
extracts the value of the Stata scalar {cmd:X}.

{synoptset 62 tabbed}{...}
{synopthdr:Function}
{synoptline}
{synopt:{bf:SF_nobs()}}Number of observations in Stata data set{p_end}
{synopt:{bf:SF_nvar()}}Number of variables{p_end}
{synopt:{bf:SF_varindex(s::AbstractString)}}Index of variable named s in data set{p_end}
{synopt:{bf:SF_var_is_string(i::Int)}}Whether variable i is string{p_end}
{synopt:{bf:SF_var_is_strl(i::Int)}}Whether variable i is a strL{p_end}
{synopt:{bf:SF_var_is_binary(i::Int, j::Int)}}Whether observation i of variable j is a binary strL{p_end}
{synopt:{bf:SF_sdatalen(i::Int, j::Int)}}String length of variable i, observation j{p_end}
{synopt:{bf:SF_is_missing()}}Whether a Float64 value is Stata missing{p_end}
{synopt:{bf:SV_missval()}}Stata floating-point value for missing{p_end}
{synopt:{bf:SF_vstore(i::Int, j::Int, val::Real)}}Set observation j of variable i to val (numeric){p_end}
{synopt:{bf:SF_sstore(i::Int, j::Int, s::AbstractString)}}Set observation j of variable i to s (string) {p_end}
{synopt:{bf:SF_vdata(i::Int, j::Int)}}Return observation j of variable i (numeric){p_end}
{synopt:{bf:SF_sdata(i::Int, j::Int)}}Return observation j of variable i (string){p_end}
{synopt:{bf:SF_macro_save(mac::AbstractString, tosave::AbstractString)}}Set macro value{p_end}
{synopt:{bf:SF_macro_use(mac::AbstractString, maxlen::Int)}}First maxlen characters of macro mac{p_end}
{synopt:{bf:SF_scal_save(scal::AbstractString, val::Real)}}Set scalar value{p_end}
{synopt:{bf:SF_scal_use(scal::AbstractString)}}Return scalar scal{p_end}
{synopt:{bf:SF_row(mat::AbstractString)}}Number of rows of matrix mat{p_end}
{synopt:{bf:SF_col(mat::AbstractString)}}Number of columns of matrix mat{p_end}
{synopt:{bf:SF_macro_save(mac::AbstractString, tosave::AbstractString)}}Set macro value{p_end}
{synopt:{bf:SF_mat_store(mat::AbstractString, i::Int, j::Int, val::Real)}}mat[i,j] = val{p_end}
{synopt:{bf:SF_mat_el(mat::AbstractString, i::Int, j::Int)}}Return mat[i,j]{p_end}
{synopt:{bf:SF_display(s::AbstractString)}}Print to Stata results window{p_end}
{synopt:{bf:SF_error(s::AbstractString)}}Print error to Stata results window{p_end}
{synoptline}
{p2colreset}{...}


{title:Author}

{p 4}David Roodman{p_end}
{p 4}david@davidroodman.com{p_end}


{title:Acknowledgements}

{pstd}
This project was inspired by James Fiedler's {browse "https://ideas.repec.org/c/boc/bocode/s457688.html":Python plugin for Stata} (as perhaps
was Stata's support for Python).


