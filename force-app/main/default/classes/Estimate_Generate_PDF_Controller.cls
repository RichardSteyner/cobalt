public with sharing class Estimate_Generate_PDF_Controller {
    public Organization Company {get;set;}
    public String OwnerName {get;set;}
    public Estimate__c E {get;set;}
    public Boolean Errors {get;set;}
    public list<Estimate_Line_Item__c> items {get;set;}
    public list<Estimate_Line_Item__c> items_suggested {get;set;}
    public list<Estimate_Line_Item__c> items_group {get;set;}


    public static String suggested {get{return 'suggested';}}
    public static String nosuggested {get{return 'no-suggested';}}

    public List<Decimal> listSeq = new List<Decimal> ();
    public list<Estimate_Line_Item__c> Temp_items;
    public list<Estimate_Line_Item__c> Temp_items_suggested;

    public Map<Decimal,Map<String,List<Estimate_Line_Item__c>>> MapTypeItemsPublic {
        get{
            return MapTypeItems;
        }
    }
    public Map<Decimal,Map<String,List<Estimate_Line_Item__c>>> MapTypeItems = new Map<Decimal,Map<String,List<Estimate_Line_Item__c>>>();
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
    
    public Map<String,List<Estimate_Line_Item__c>> MapContainerNoSuggestedTemp = new Map<String,List<Estimate_Line_Item__c>>();
    public Map<String,List<Estimate_Line_Item__c>> MapContainerSuggestedTemp = new Map<String,List<Estimate_Line_Item__c>>();

    public Map<Decimal,List<Estimate_Line_Item__c>> MapItems = new Map<Decimal,List<Estimate_Line_Item__c>> ();
   
    public Map<Decimal,Estimate_Summary_Detail> MapSummaryDetail = new Map<Decimal,Estimate_Summary_Detail> ();
    public Map<Decimal,Estimate_Summary_Detail> MapSummaryDetailPublic{
        get{
            return MapSummaryDetail;
        }
    }
    public Estimate_Summary_Detail SummaryTemp;
    
    public Estimate_Generate_PDF_Controller() {}
    public Estimate_Generate_PDF_Controller(ApexPages.StandardController sc) {
        Errors = false;
        E = (Estimate__c) sc.getRecord();
        System.debug('Estimate: '  + E);
        try{ 

            System.debug('--------------------------- SOQL ZONE -----------------------------');
            E = [
                SELECT 
                    Id,Name,Ship_to_Company_name__c,Ship_to_Street_Address__c,Ship_to_City__c,Ship_to_State__c,Ship_to_Zip_code__c,Bill_to_Company_Name__c,Bill_to_street_address__c,Bill_to_City__c,Bill_to_State__c,Bill_to_Zip_code__c,Revision__c,Estimate_Date__c,Estimate_Valid_until__c,Sales_Rep__c,Sold_to_Customer__r.Terms__c,Sales_Rep__r.Name,Unit__c,Unit__r.Name,Unit__r.Make__c,Unit__r.Model__c,Unit__r.Year__c,Unit__r.VIN__c,Estimate_Selling_Price__c,Client_Comments__c,Estimate_Suggested_Price__c
                FROM  Estimate__c WHERE Id = :E.Id
            ];
            
            Apexpages.currentPage().getHeaders().put('content-disposition', 'inline; filename=Estimate Unit #'+E.Unit__r.Name+'.pdf');
            
            Company = [
                SELECT    
                    Id,Name,Street,City,State,PostalCode,Country,StateCode,CountryCode,Phone,Fax 
                FROM Organization WHERE Id = :UserInfo.getOrganizationId()
            ];
            System.debug('Company' + Company);
    
            items = [
                SELECT 
                    Id,Name,Estimate__c,Part_number__c,Part_number__r.Description,Part_number__r.Name,Seq__c,Seq_Notes__c,Seq_Title__c,Quantity__c,Description__c,Suggested__c,UOM__c,Price__c,Selling_Price__c,Est_Price__c,Price_Type__c,Regular_Cost__c,Freight_in__c,Bid_Cost__c,Total_Price__c,Regular_Price__c,Landed_cost__c,Standard_Cost__c,Unknown_Part_Name__c,Part_Number_Family__c,Part_Number_Description__c,Total_Price_Formula__c,Standard_Cost_Formula__c
                FROM Estimate_Line_Item__c WHERE Estimate__c = :E.Id AND Suggested__c=FALSE ORDER BY Seq__c Asc
            ];
            System.debug('items' + items);

            items_suggested = [
                SELECT 
                    Id,Name,Estimate__c,Part_number__c,Part_number__r.Description,Part_number__r.Name,Seq__c,Seq_Notes__c,Seq_Title__c,Quantity__c,Description__c,Suggested__c,UOM__c,Price__c,Est_Price__c,Price_Type__c,Regular_Cost__c,Freight_in__c,Bid_Cost__c,Total_Price__c,Regular_Price__c,Landed_cost__c,Selling_Price__c,Standard_Cost__c,Unknown_Part_Name__c,Part_Number_Family__c,Part_Number_Description__c,Total_Price_Formula__c,Standard_Cost_Formula__c
                FROM Estimate_Line_Item__c WHERE Estimate__c = :E.Id AND Suggested__c=True ORDER BY Seq__c Asc
            ];
            System.debug('items_suggested' + items_suggested);
            
            System.debug('--------------------------- Procesing Data Map-List ZONE -----------------------------');
            System.debug('           --------------- NO SUGGESTED Data Map-List ZONE -------------------');
            for(Estimate_Line_Item__c litem : items){
                if(litem.Seq__c != null){
                    MapContainerNoSuggestedTemp = MapTypeItems.get(litem.Seq__c);
                    SummaryTemp = MapSummaryDetail.get(litem.Seq__c);

                    if(MapContainerNoSuggestedTemp == null){
                        MapContainerNoSuggestedTemp = new Map<String,List<Estimate_Line_Item__c>>();
                        Temp_items = new List<Estimate_Line_Item__c>();
                        SummaryTemp = new Estimate_Summary_Detail();
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
            for(Estimate_Line_Item__c litems : items_suggested){
                if(litems.Seq__c != null){
                    MapContainerSuggestedTemp = MapTypeItems.get(litems.Seq__c);
                    SummaryTemp = MapSummaryDetail.get(litems.Seq__c);

                    if(MapContainerSuggestedTemp == null){
                        MapContainerSuggestedTemp = new Map<String,List<Estimate_Line_Item__c>>();
                        SummaryTemp = new Estimate_Summary_Detail();
                    }

                    Temp_items = MapContainerSuggestedTemp.get('suggested');
                    if(Temp_items == null){
                        Temp_items = new List<Estimate_Line_Item__c>();                        
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

            Map<Decimal,Map<String,List<Estimate_Line_Item__c>>> MapTypeTemp = new Map<Decimal,Map<String,List<Estimate_Line_Item__c>>>();
            Map<String,List<Estimate_Line_Item__c>> verify = new Map<String,List<Estimate_Line_Item__c>>();
            for(Decimal key : MapTypeItems.keySet()){
                verify = MapTypeItems.get(key);
                if( verify.get('suggested') == null){
                    verify.put('suggested',new List<Estimate_Line_Item__c>());
                }
                
                verify = MapTypeItems.get(key);
                if( verify.get('no-suggested') == null){
                    verify.put('no-suggested',new List<Estimate_Line_Item__c>());
                }
            }


            System.debug('--------------------------- Final Results ZONE -----------------------------');
            
            System.debug('MapTypeItems '+MapTypeItems);
            System.debug('MapSummaryDetail ' +MapSummaryDetail);

        }catch(Exception ex){
            Errors = True;
            ApexPages.addMessage(new 
                ApexPages.Message(ApexPages.Severity.ERROR, 
               'Ah an error occurred'));
            System.debug('Line: ' + ex.getLineNumber() + ' - Message: ' + ex.getMessage());
        }
    }

}