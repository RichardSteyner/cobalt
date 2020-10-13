public with sharing class Invoice_Generate_PDF_Controller {
    public Invoice__c I {get;set;}
    public Organization Company {get;set;}
    public Boolean Errors {get;set;}
    //public list<Invoice_line_item__c> items {get;set;}
    //public list<Invoice_line_item__c> items_suggested {get;set;}
    public Map<Decimal,Map<String,List<Invoice_line_item__c>>> MapTypeItems = new Map<Decimal,Map<String,List<Invoice_line_item__c>>>();
    /** 
     * Sample MapItems
     * 
     * [
     *      {
     *          "seq number": [
     *              {
     *                  "suggested": [
     *                      {},{},{},{}
     *                  ]
     *              },{
     *                  "no-suggested": [
     *                      {},{},{},{}
     *                  ]
     *              }
     *          ]
     *      },{
     *          "seq number": [
     *              {
     *                  "suggested": [
     *                      {},{},{},{}
     *                  ]
     *              },{
     *                  "no-suggested": [
     *                      {},{},{},{}
     *                  ]
     *              }
     *          ]
     *      }
     * ]
     * 
     * 
     * */
    public Map<Decimal,Summary_Detail> MapSummaryDetail = new Map<Decimal,Summary_Detail> ();
    
    public Map<Decimal,Summary_Detail> MapSummaryDetailPublic{
        get{
            return MapSummaryDetail;
        }
    }
    public Map<Decimal,Map<String,List<Invoice_line_item__c>>> MapTypeItemsPublic {
        get{
            return MapTypeItems;
        }
    }

    public Invoice_Generate_PDF_Controller() {}
    public Invoice_Generate_PDF_Controller(ApexPages.StandardController sc) {
        Map<String,List<Invoice_line_item__c>> MapContainerNoSuggestedTemp = new Map<String,List<Invoice_line_item__c>>();
        Map<String,List<Invoice_line_item__c>> MapContainerSuggestedTemp = new Map<String,List<Invoice_line_item__c>>();    
        Map<Decimal,List<Invoice_line_item__c>> MapItems = new Map<Decimal,List<Invoice_line_item__c>> ();
   
        String fakeDate = apexpages.currentpage().getparameters().get('fakedate');
        
        Errors = false;
        I = (Invoice__c) sc.getRecord();
        System.debug('Invoice: '  + I);

        try{ 
            I = [
                SELECT 
                    Id,
                    Name,
                    Ship_to_Company_name__c,
                    Ship_to_Street_Address__c,
                    Ship_to_City__c,
                    Ship_to_State__c,
                    Ship_to_Zip_code__c,
                    Bill_to_Company_Name__c,
                    Bill_to_street_address__c,
                    Bill_to_City__c,
                    Bill_to_State__c,
                    Bill_to_Zip_code__c,
                    Sales_Rep__c,
                    Sold_to_Customer__r.Terms__c,
                    Sold_to_Customer__r.Name,
                    Sales_Rep__r.Name,
                    Unit__c,
                    Unit__r.Name,
                    Unit__r.Make__c,
                    Unit__r.Model__c,
                    Unit__r.Year__c,
                    Unit__r.VIN__c	,
                    Client_Comments__c,
                    Order_date__c,
                    Invoice_date__c,
                    Customer_PO__c,
                    Subtotal__c,
                    Sales_Tax__c,
                    Order_Total__c,
                    Hide_Line_items__c,
                    Invoice_Selling_Price__c,
                    Invoice_Suggested_Price__c
                FROM  Invoice__c WHERE Id = :I.Id
            ];
            if(I.Invoice_date__c == null && fakeDate != null)
                I.Invoice_date__c = date.valueOf(fakeDate);
                
            Apexpages.currentPage().getHeaders().put('content-disposition', 'inline; filename=Invoice ' + I.Name +'.pdf');
            
            Company = [
                SELECT    
                    Id,
                    Name,
                    Street,
                    City,
                    State,
                    PostalCode,
                    Country,
                    StateCode,
                    CountryCode,
                    Phone,
                    Fax 
                FROM Organization WHERE Id = :UserInfo.getOrganizationId()
            ];
            System.debug(Company);
            list<Invoice_line_item__c> items = new list<Invoice_line_item__c>();
            list<Invoice_line_item__c> items_suggested = new list<Invoice_line_item__c>();
            if(!I.Hide_Line_items__c){
                items = [
                    SELECT 
                        Id,
                        Name,
                        Invoice__c,
                        Part_number__c,
                        Part_number__r.Description,
                        Part_number__r.Name,
                        Seq__c,
                        Seq_Title__c,
                        Seq_Notes__c,
                        Quantity__c,
                        Description__c,
                        Suggested__c,
                        UOM__c,
                        Price__c,
                        Selling_Price__c,
                        Price_Type__c,
                        Regular_Cost__c,
                        Freight_in__c,
                        Bid_Cost__c,
                        Total_Price__c,
                        Regular_Price__c,
                        Landed_cost__c,
                        Standard_Cost__c,
                        Unknown_Part_Name__c,
                        Part_Number_Family__c,
                        Part_Number_Description__c,
                        Total_Price_Formula__c,
                        Standard_Cost_Formula__c
                    FROM Invoice_line_item__c WHERE Invoice__c = :I.Id AND Suggested__c=FALSE ORDER BY Seq__c Desc
                ];
                System.debug(items);

                items_suggested = [
                    SELECT 
                        Id,
                        Name,
                        Invoice__c,
                        Part_number__c,
                        Part_number__r.Description,
                        Part_number__r.Name,
                        Seq__c,
                        Seq_Title__c,
                        Seq_Notes__c,
                        Quantity__c,
                        Description__c,
                        Suggested__c,
                        UOM__c,
                        Price__c,
                        Selling_Price__c,
                        Price_Type__c,
                        Regular_Cost__c,
                        Freight_in__c,
                        Bid_Cost__c,
                        Total_Price__c,
                        Regular_Price__c,
                        Landed_cost__c,
                        Standard_Cost__c,
                        Unknown_Part_Name__c,
                        Part_Number_Family__c,
                        Part_Number_Description__c,
                        Total_Price_Formula__c,
                        Standard_Cost_Formula__c
                    FROM Invoice_line_item__c WHERE Invoice__c = :I.Id AND Suggested__c=TRUE ORDER BY Seq__c Desc
                ];
                System.debug(items_suggested);
            }
            
            System.debug('--------------------------- Procesing Data Map-List ZONE -----------------------------');
            System.debug('           --------------- NO SUGGESTED Data Map-List ZONE -------------------');
            
            Summary_Detail SummaryTemp;
            list<Invoice_line_item__c> Temp_items;
            for(Invoice_line_item__c litem : items){
                if(litem.Seq__c != null){
                    MapContainerNoSuggestedTemp = MapTypeItems.get(litem.Seq__c);
                    SummaryTemp = MapSummaryDetail.get(litem.Seq__c);

                    if(MapContainerNoSuggestedTemp == null){
                        MapContainerNoSuggestedTemp = new Map<String,List<Invoice_line_item__c>>();
                        Temp_items = new List<Invoice_line_item__c>();
                        SummaryTemp = new Summary_Detail();
                    }else{
                        Temp_items = MapContainerNoSuggestedTemp.get('no-suggested');
                    }

                    System.debug('Before Seq = ' + litem.Seq__c + ' : ' +SummaryTemp.Total_no_suggested);
                    SummaryTemp.Total_no_suggested += litem.Total_Price_Formula__c;
                    System.debug('After Seq = ' + litem.Seq__c + ' : ' +SummaryTemp.Total_no_suggested);

                    SummaryTemp.Title = litem.Seq_Title__c != null ? litem.Seq_Title__c : SummaryTemp.Title;
                    SummaryTemp.Description = litem.Seq_Notes__c != null ? litem.Seq_Notes__c : SummaryTemp.Description;
                    MapSummaryDetail.put(litem.Seq__c,SummaryTemp);

                    Temp_items.add(litem);
                    MapContainerNoSuggestedTemp.put('no-suggested',Temp_items);
                    MapTypeItems.put(litem.Seq__c,MapContainerNoSuggestedTemp);
                }

            }

            System.debug('           --------------- SUGGESTED Data Map-List ZONE -------------------');
            for(Invoice_line_item__c litems : items_suggested){
                if(litems.Seq__c != null){
                    MapContainerSuggestedTemp = MapTypeItems.get(litems.Seq__c);
                    SummaryTemp = MapSummaryDetail.get(litems.Seq__c);

                    if(MapContainerSuggestedTemp == null){
                        MapContainerSuggestedTemp = new Map<String,List<Invoice_line_item__c>>();
                        SummaryTemp = new Summary_Detail();
                    }

                    Temp_items = MapContainerSuggestedTemp.get('suggested');
                    if(Temp_items == null){
                        Temp_items = new List<Invoice_line_item__c>();                        
                    }
                    System.debug('Before Seq = ' + litems.Seq__c + ' : ' +SummaryTemp.Total_suggested);
                    SummaryTemp.Total_suggested += litems.Total_Price_Formula__c;
                    System.debug('After Seq = ' + litems.Seq__c + ' : ' +SummaryTemp.Total_suggested);

                    SummaryTemp.Title = litems.Seq_Title__c != null ? litems.Seq_Title__c : SummaryTemp.Title;
                    SummaryTemp.Description = litems.Seq_Notes__c != null ? litems.Seq_Notes__c : SummaryTemp.Description;
                    MapSummaryDetail.put(litems.Seq__c,SummaryTemp);
                    
                    Temp_items.add(litems);
                    
                    MapContainerSuggestedTemp.put('suggested',Temp_items);
                    MapTypeItems.put(litems.Seq__c,MapContainerSuggestedTemp);
                }

            }

            Map<Decimal,Map<String,List<Invoice_line_item__c>>> MapTypeTemp = new Map<Decimal,Map<String,List<Invoice_line_item__c>>>();
            Map<String,List<Invoice_line_item__c>> verify = new Map<String,List<Invoice_line_item__c>>();
            for(Decimal key : MapTypeItems.keySet()){
                verify = MapTypeItems.get(key);
                if( verify.get('suggested') == null){
                    verify.put('suggested',new List<Invoice_line_item__c>());
                }
                
                verify = MapTypeItems.get(key);
                if( verify.get('no-suggested') == null){
                    verify.put('no-suggested',new List<Invoice_line_item__c>());
                }
            }


            System.debug('--------------------------- Final Results ZONE -----------------------------');
        }catch(Exception ex){
            Errors = True;
            ApexPages.addMessage(new 
                ApexPages.Message(ApexPages.Severity.ERROR, 
               'Ah an error occurred'));
            System.debug(ex.getLineNumber() + ' - ' +ex.getMessage());
        }
    }

    public class Summary_Detail {
        public Decimal Total_suggested {get;set;}
        public Decimal Total_no_suggested {get;set;}
        public String Title {get; set;}
        public String Description {get; set;}
        public Summary_Detail(){
            Total_suggested = 0;
            Total_no_suggested = 0;
        }
    }
}