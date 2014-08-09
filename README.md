# Koi

<img src="http://fc02.deviantart.net/fs41/f/2009/031/7/8/The_Koi_Fish_by_JaZaDesign.jpg" align="right" style="float:right;" width="200px" />


**Koi** is a simple application to organize the financial transactions of your family.

This application is aimed at all the families whose members have a personal bank account and use it for their normal daily life, combining personal transactions and common expenses.

With Koi, you can easily keep track of all the sources of income and the targets of your expenses, with a clear overview of every transaction, as well as monthly and yearly breakdowns.

And charts, everybody loves charts.

## Setup

Create a PostgreSQL Database with the name `koi`, and you're good to
go!

This is a normal Sinatra application, so start it normally with

    RACK_ENV=production ruby koi.rb

Then visit `http://localhost:4567` and/or have other people in your local
network visit your ip with that port.

## License

See [LICENSE.md](LICENSE.md)
