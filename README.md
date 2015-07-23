A Web Application for Displaying Results of the Termination Competition
-----------------------

The Intl. Termination Competition 2014 <http://termination-portal.org/wiki/Termination_Competition_2014> will be run on <http://www.starexec.org> . 

Our Web App will provide these extra features:

* computation and display of results per category, 
  and medalists per meta-category
* flexible 2-dimensional results tables 
  (x-axis: solver, y-axis: benchmark) 
  (with filters for rows and columns, sorters, etc.)
* caching (and permanent storage) of results 
  (we intend to include also results of earlier competitions)

Getting source
--------------
There may be submodules, so:

    git clone --recursive ...


Installation
------------
    cabal sandbox init
    cabal sandbox add-source graphviz
    cabal install alex happy yesod-bin
    cabal install --enable-tests .

Usage
-----

    yesod devel

* create user: sudo -u postgres createuser -P yesod
* clear db: sudo -u postgres dropdb yesod
* create db: sudo -u postgres createdb -O yesod yesod
* access db: sudo -u postgres psql -d yesod
