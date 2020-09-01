public with sharing class Estimate_Summary_Detail {
    public Decimal Total_suggested {get;set;}
    public Decimal Total_no_suggested {get;set;}
    public String Title {get; set;}
    public String Description {get; set;}
    public Estimate_Summary_Detail(){
        Total_suggested = 0;
        Total_no_suggested = 0;
    }
}