# Liquid-dashboard
Liquid-dashboard is a Shiny/R project able to visualize charts about Liquid sidechain performances.

Liquid-dashboard is able to show:

- statistical data about blocks and transactions
- transactions with OP_RETURN not connected to coinbase, pegin or pegout transactions

# Working example
You can check a working example of the dashboard [here](http://vaccaro.tech:3838/liquid/).

## Main dashboard
![Price dashboard](https://raw.githubusercontent.com/valerio-vaccaro/Liquid-dashboard/master/screenshots/Main.png)

## OP_RETURN dashboard
![OP_RETURN dashboard](https://raw.githubusercontent.com/valerio-vaccaro/Liquid-dashboard/master/screenshots/op_return.png)

# Make it work
Follows this steps in order to clone this project:

* Clone the repository in your shiny app folder.
* Execute the script get_data.R every hour in order to fetch new datasets - maybe calling rscript from cron.
* Enjoy the charts available with this simple shiny app.

All the code is available at https://github.com/valerio-vaccaro/Liquid-dashboard

The dataset is generate using free API from the explorer blockstream.info.

# License
Copyright (c) 2018 Valerio Vaccaro http://www.valeriovaccaro.it

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
