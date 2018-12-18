# server.R
library(ggplot2)
library(ggpmisc)
library(anytime)
library(grid)
library(stringr)
library(RJSONIO)
library(Rbitcoin)
library(plyr)
library(igraph)
library(dplyr)
library(lubridate)

setwd("~/r-studio-workspace/bitcoin/liquid")

server <- function(input, output) {
  
  # load data
  load("./data/liquid_blocks.RData")
  load("./data/liquid_transactions.RData")
  load("./data/liquid_transactions_op_return.RData")
  
  today <- as.numeric(as.POSIXct(Sys.Date()))*1000
  
  
  output$dateSelector <- renderUI({
      if(input$radio==1) days=1
      else if(input$radio==2) days=7
      else if(input$radio==3) days=30
      MIN <- min(transactions$height)
      MAX <- max(transactions$height)
      sliderInput(
        "height",
        "Select start and stop height",
        min = MIN,
        max = MAX ,
        value = c(MAX -  days*24*60,  MAX)
      )
  })
   
   output$dateBox <- renderInfoBox({
      infoBox(
         "Blocks",
         paste0("Current height: ",max(blocks$height)),
         icon = icon("server"),
         color = "green"
      )
   })

   output$speedBox <- renderInfoBox({
      infoBox(
         "Transactions",
         HTML(paste0("Transactions: ",nrow(transactions),br(),"Total fees: ",round(sum(transactions$fee)/100000000, digits = 3), " Liquid BTC")),
         icon = icon("shopping-cart"),
         color = "yellow"
      )
   })

   output$pulseBox <- renderInfoBox({
      infoBox(
         "Peg in/out",
         HTML(paste0("Peg in transactions: ",sum(transactions$vin_is_pegin),br(),"Peg out transactions: ",sum(transactions$vout_is_pegout))),
         icon = icon("bitcoin"),
         color = "red"
      )
   })
   
   transactions$kind <- "Standard"

   transactions[transactions$vin_is_coinbase, "kind"] <- "Coinbase"
   transactions[transactions$vin_is_pegin, "kind"] <- "Pegin"
   transactions[transactions$vout_is_pegout, "kind"] <- "Pegout"
   
   transactions$kind <- as.factor(transactions$kind)
   
   output$a11 <- renderPlot({
      filter <- transactions$kind == "none"
      if (1 %in% input$checkGroup)
        filter <- filter | (transactions$kind == "Coinbase")
      if (2 %in% input$checkGroup)
        filter <- filter | (transactions$kind == "Pegin")
      if (3 %in% input$checkGroup)
        filter <- filter | (transactions$kind == "Pegout")
      if (4 %in% input$checkGroup)
        filter <- filter | (transactions$kind == "Standard")
      
      filter_time <- (transactions$height >= input$height[[1]]) & (transactions$height <= input$height[[2]]) 
      
      filter <- filter & filter_time
        
      ggplot(data=transactions[filter, ], aes(x=height, y=size, color=kind, alpha=0.1)) +
         geom_point() +
         labs(title="Liquid transaction size",
              x ="Height", y = "Size") +
         theme(axis.text.x = element_text(angle=45, hjust=1)) 
   })
   
   output$a12 <- renderPlot({
      filter <- transactions$kind == "none"
      if (1 %in% input$checkGroup)
        filter <- filter | (transactions$kind == "Coinbase")
      if (2 %in% input$checkGroup)
        filter <- filter | (transactions$kind == "Pegin")
      if (3 %in% input$checkGroup)
        filter <- filter | (transactions$kind == "Pegout")
      if (4 %in% input$checkGroup)
        filter <- filter | (transactions$kind == "Standard")
      
      filter_time <- (transactions$height >= input$height[[1]]) & (transactions$height <= input$height[[2]]) 
      
      filter <- filter & filter_time
      
      ggplot(data=transactions[filter, ], aes(x=size, fill=kind)) +
         geom_histogram() +
         labs(title="Liquid transaction size",
              x ="Size", y = "#transactions") +
         theme(axis.text.x = element_text(angle=45, hjust=1)) 
   })
   
   output$a21 <- renderPlot({
      filter <- transactions$kind == "none"
      if (1 %in% input$checkGroup)
        filter <- filter | (transactions$kind == "Coinbase")
      if (2 %in% input$checkGroup)
        filter <- filter | (transactions$kind == "Pegin")
      if (3 %in% input$checkGroup)
        filter <- filter | (transactions$kind == "Pegout")
      if (4 %in% input$checkGroup)
        filter <- filter | (transactions$kind == "Standard")
      
      filter_time <- (transactions$height >= input$height[[1]]) & (transactions$height <= input$height[[2]]) 
      
      filter <- filter & filter_time
      
      ggplot(data=transactions[filter, ], aes(x=height, y=fee, color=kind, alpha=0.1)) +
         geom_point() +
         labs(title="Liquid transaction fee",
              x ="Height", y = "Fee") +
         theme(axis.text.x = element_text(angle=45, hjust=1)) 
   })
   
   output$a22 <- renderPlot({
      filter <- transactions$kind == "none"
      if (1 %in% input$checkGroup)
        filter <- filter | (transactions$kind == "Coinbase")
      if (2 %in% input$checkGroup)
        filter <- filter | (transactions$kind == "Pegin")
      if (3 %in% input$checkGroup)
        filter <- filter | (transactions$kind == "Pegout")
      if (4 %in% input$checkGroup)
        filter <- filter | (transactions$kind == "Standard")
      
      filter_time <- (transactions$height >= input$height[[1]]) & (transactions$height <= input$height[[2]])
      
      filter <- filter & filter_time
     
      ggplot(data=transactions[filter, ], aes(x=fee, fill=kind)) +
         geom_histogram() +
         labs(title="Liquid transaction fee",
              x ="Fee", y = "#transactions") +
         theme(axis.text.x = element_text(angle=45, hjust=1)) 
   })
   
   op_return <- tx_op_return[,c("height","txid","text","hex")]
   op_return <- op_return[order(op_return$height),]
   output$op_return <- renderDataTable(op_return)
}