*******************************************************************************************
*  Version 0.4: 2021-02-01
*******************************************************************************************
*  Dennis Föste-Eggers	
*
*  German Centre for Higher Education Research and Science Studies (DZHW)
*  Lange Laube 12, 30159 Hannover         
*  Phone: +49-(0)511 450 670-114		
*  E-Mail (1): foeste-eggers@dzhw.eu  	
*  E-Mail (2): dennis.foeste@gmx.de
*  E-Mail (3): dennis.foeste@outlook.de
*
*******************************************************************************************
*  Program name: k10i08.ado     
*  Program purpose: Application of a transfer key from KldB2010 to ISCO08 
*					provided by the Bundesagentur fuer Arbeit (2011).			
*******************************************************************************************
*  Changes made:
*  Version 0.1: added GPL 
*  Version 0.2: added checks  
*  Version 0.3: added passthru options
*  Version 0.4: extended use of tempvars
*******************************************************************************************
*  License: GPL (>= 3)
*     
*	k10i08.ado for Stata
*   Copyright (C) 2020 Foeste-Eggers, Dennis 
*
*   This program is free software: you can redistribute it and/or modify
*   it under the terms of the GNU General Public License as published by
*   the Free Software Foundation, either version 3 of the License, or
*   (at your option) any later version.
*
*   This program is distributed in the hope that it will be useful,
*   but WITHOUT ANY WARRANTY; without even the implied warranty of
*   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*   GNU General Public License for more details.
*
*   You should have received a copy of the GNU General Public License
*   along with this program.  If not, see <https://www.gnu.org/licenses/>.
*
*******************************************************************************************
*  Citation: This code is © D. Foeste-Eggers, 2020, and it is made 
*				 available under the GPL license enclosed with the software.
*
*!			Over and above the legal restrictions imposed by this license, if you use this 	!
*! 			program for any (academic) publication then you are obliged to provide proper 	!
*!			attribution. 																	!
*
*   D. Foeste-Eggers k10i08.ado for Stata, v0.4 (2021). 
*			[weblink].
*
*******************************************************************************************


cap program drop k10i08
program define k10i08  , nclass
	version 15

	if ("`c(excelsupport)'" != "1") {
		dis as err `"import excel is not supported on this platform."'
		exit 198
	}
	
	syntax varlist(min=1 numeric) [if] [in] [, 			///
								GENerate(newvarlist)	/// was namelist before
								XLSfile(passthru)		///
								sheet(passthru)			/// undocumented
								cellrange(passthru)]	//  undocumented
	

			di ""
			di "Umsetzung des Umsteigeschluessel-KldB2010-ISCO-08 (BA 2011)" 
			di "      via k10i08.ado by Foeste-Eggers (2021), Version 0.4"
			di ""			
			di "Quelle: Bundesagentur für Arbeit - Statistik (2011):"
			di "        Umsteigeschlüssel von der Klassifikation der Berufe 2010 (5-Steller)" 
			di "        zur ISCO-08 (4-Steller)"
			di ""
			qui {
				preserve 
					* Importieren der Daten
					* --> relativen statt fixen Dateibezug einbauen
					if `"`xlsfile'"' == "" {
						import excel "https://statistik.arbeitsagentur.de/DE/Statischer-Content/Grundlagen/Klassifikationen/Klassifikation-der-Berufe/KldB2010/Arbeitshilfen/Umsteigeschluessel/Generische-Publikation/Umsteigeschluessel-KldB2010-ISCO-08.xls?__blob=publicationFile&v=5", sheet("Umsteiger KldB 2010 auf ISCO") cellrange(A5:F1508) firstrow clear 
					}
					else if `"`sheet'"' == "" {
							import excel `xlsfile', sheet("Umsteiger KldB 2010 auf ISCO") cellrange(A5:F1508) firstrow clear 
						}
						else if `"`sheet'"' == "" {
								import excel `xlsfile', sheet(`sheet') cellrange(A5:F1508) firstrow clear 
							}
							else import excel `xlsfile', sheet(`sheet') cellrange(`cellrange') firstrow clear 
					* "P:\panel\Ados\David_und_Dennis\Umsteigeschluessel-KldB2010-ISCO-08.xls"
					destring KldB20105Steller ISCO084Steller Umstiegeindeutig1nichtein Schwerpunkt1undAnzahlder, replace 
					
					* Konsistenzpruefungen
					egen minschwp = min( Schwerpunkt1undAnzahlder),  by(KldB20105Steller)
					sum minschwp
					egen maxschwp = max( Schwerpunkt1undAnzahlder),  by(KldB20105Steller)
					sum Umstiegeindeutig1nichtein if minschwp==maxschwp & minschwp==1
					if r(min)==r(max) & r(max)==1 {
						noi di as txt  "Konsistenzpruefung (1): als eindeutig markierte Zuordnungen sind eindeutig"
					}
					else {
						noi di in red "Konsistenzpruefung (1): als eindeutig markierte Zuordnungen sind nicht eindeutig"
					}
					local eindeut   = r(N)
					sum Umstiegeindeutig1nichtein if minschwp~=maxschwp
					if r(min)==r(max) & r(max)==0 {
						noi di  "Konsistenzpruefung (2): als uneindeutig markierte Zuordnungen sind uneindeutig"
					}
					else {
						noi di in red "Konsistenzpruefung (2): als uneindeutig markierte Zuordnungen sind nicht uneindeutig"
					}
					local uneindeut = r(N)
					gen schwp = (Schwerpunkt1undAnzahlder==1)
					egen totschwp = total(schwp) , by(KldB20105Steller)
					sum  totschwp
					if r(max)==1 {
						noi di  "Konsistenzpruefung (3): es wurde jeweils nur ein Schwerpunkt gesetzt"
					}
					else {
						noi di in red "Konsistenzpruefung (3): es wurde teilweis nicht nur ein Schwerpunkt gesetzt"
					}
					local n_tot = r(N)
					*if r(N)== `=`eindeut' + `uneindeut'' noi di  "Konsistenzpruefung (4): "
					
					* Zusammenfassung
					noi di ""
					noi di `"`eindeut' der `n_tot' Zuordnungen sind eindeutig"'
					noi di `" `uneindeut' der `n_tot' Zuordnungen sind nicht eindeutig"'
					
					* Vorbereitung des Mergens
					keep if Schwerpunkt1undAnzahlder == 1
					keep KldB20105Steller ISCO084Steller 
					* --> probieren ob tempname hier funktioniert
					rename (KldB20105Steller ISCO084Steller) (K20105_Steller_tv I08_4Steller_tv)
					
					tempfile k10i08temp
					save `"`k10i08temp'"'
					
				restore
			}
	
	*mark sample		
	tempvar touse 
	mark `touse' `if' `in'
	
	
	
	local n = 0
	qui foreach var of varlist `varlist' {
	    local ++n 
		local undo = 0
		* noi sum _all
		tempvar rslt_mrg k10
	    cap gen K20105_Steller_tv = `var' if `touse'
		if _rc==110 {
			clonevar `k10' = K20105_Steller_tv
			drop K20105_Steller_tv
			local undo = 1
		}
		*tempname rslt_mrg
		noi merge m:1 K20105_Steller_tv  using ///
		`"`k10i08temp'"' , ///  
		generate(`rslt_mrg')
		drop if (`rslt_mrg'==2)
		noi di "Fuer folgende Codes erfolgte keine Zuordnung"
		noi tab K20105_Steller_tv if (`rslt_mrg'==1), mi nolab
		local name : word `n' of `generate'
		rename I08_4Steller_tv `name'
		if undo == 1 {
			drop K20105_Steller_tv `rslt_mrg'
			clonevar K20105_Steller_tv = `k10' 
			drop `k10' 
		}
		else drop K20105_Steller_tv `rslt_mrg' `k10'
	}
	
	
end



