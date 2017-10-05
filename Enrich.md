#batch-enrich is an openSRF service

This module is an optional service to enrich reports with xslt stylesheets.
##1. Intended behaviour
Enrichment needs a CSV list with TC-numbers in them. Create reports to make such lists.
For each record in the list, your custom made xslt will be applied. 

Only one enrichment procedure is possible at any one time.

##2. Permissions
To use the service, you need the role 'BATCH_ENRICH'.
##3. Select records to undergo change
Create a report for the records via the reports module. Make sure the output is CSV format and has a column called "TCN" with the records numbers.
If there is no "TCN" column, the procedure will take the first ( left ) column.

After you run the report, you can look at the HTML presentation. Click on the "(schedule it)" link 
##4. Add an xslt sheet
The xslt should produce an HTML table. Each row should have the -tr element and each value should be placed in the -td element.

Indicate a Title, email and the number of days to repeat the command.
 
On the left, there are some default XSLT options. You can also past in custom XSLT in the window.
On the right, you can see the effects of the change. Use the dropdown to get a MarcXML example. Each time you change
the stylesheet the XML will change accordingly... provided the stylesheet was valid.
 
##5. Run a schedule
Select "In queue" and save the record. The procedure will start in a couple of minutes.

##6. See results
Select "Show record" and click on the Enriched URL report. You can also past the link in a browser.
##Excel sheet
The enriched report is an HTML file and can be opened with an Excel sheet editor. Then save it as Excel or CSV.

