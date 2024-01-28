- [is this a decision for the Base Layer too or only for the Upper Layers?] what is the best way to distribute the rewards?
 - it has to be based on picks, so the best way would be finding out exactly amount each user earned through his staking
 -  instant send value to beneficiary or gather it for 1 week? 

- the story about the street pavement is a great example!

-   how can this snapshot be done??? lets start with one at time?

// @audit-info calculate the correct amount the user would have earned by himself. since the protocol is gathering all the yields to his own address I dont know how to get the correct one.

//@audit-info  since i don't know how to get what each user generated with his yield lets just remove his principal and give it back to him 100% but the this percentage number is IMPERATIVE for the idea of this protocol, so lets just look later


<!-- ------------------------------ -->
<!-- --------------V1-------------- -->
[todo]  
[ ] add a way for the admin to retrieve ethers sent to the contract, since there is a receive function [NOT CUSTOMERS FUND]
[x] this can have a staked Token
[x] add the time concept and staking snapshot.
[x] add some sort of checkpoint from each week/month colaborated, badges. for the badges add a minimum amount so users dont only sent 1 wei for example.
[x] add a score the user will be able to showcase
[x] [done for one stake at a time] keep track of a medium snapshot and value combined to see each users medium, not necessary at the moment, will just add more complexity to the project..
[x] add the total amount aggregated of all users
[ ] create the upper layer and decide which will stay at the base one
[ ] district / region distribution [which layer?]
[ ] include hiring category?, [which layer?]
[ ] change name beneficiary for officials like is stated in the docs?

<!-- ------------------------------ -->
<!-- --------------V2-------------- -->

[ ] [maybe move it to the Base Layer?] [THIS SHOULD BE SOULBOND] create and associate nfts as badges
[ ] add a stake with tokens too
[ ] a governance token to add new Beneficiaries
[ ] (decide which layer this goes to, the base or the higher ones) implement sporadic events and projects [e.g. build a new school]
[ ] add roles instead of a single owner, also a timelock
[ ] take a look at how to implement ZK proof of collaboration
[ ] add different types of lending. more risks == more yield, but the user should be able to choose.
[ ] add more attractive ways for the user to make money when he stakes his taxes, not only not lose money but also make some APY, this will attract users not only to help their communities but also earn something in return.

[x] deploy all things on script and use it on test instead of deploying on tests


<!-- --------------DAO-------------- -->
PROPOSERS = propose ideas that must be approved in order to be delegated by the admin
PRINCIPALS = the people that are allowed to make the project reality, the person/organization which the money will be sent to, must be trusted to build the project, also must be allowed.
BENEFICIARY = the contract/DAO that will receive from the base layer.
COLLABORATORS = a.k.a tax payers.


- is it a good idea to transform the days and value deposit into points to calculate better?
<!--  -->

// sporadic projects can only be created by admins `at least for now then find a safe way to distribute this role  for the community`.
 - only created by admin // for now
 - have a timestamp?
 - locked amount?
 - fixed amount?
 - create index so it can be easily displayed on the UI
 - a new Struct since it requires a new parameters like metadata
 

- ok so for the distribution I need to only store the amount each user staked and for how much time and them given that for each user distribute proportionally, then each day/week an admin can call a function to fairly distribute it all to the 5 categories according to their amount. after that done we simply map the values 
 - lets create a mapping to store the timestamp and the value of each category


- it can actually be used as a anti-sybil since the user collaborates 
- a 1:1 st token can be released

[audits]
// @audit [it seems so] in the aave contract what would happen if the receiver of the tokens cant handle them? would they be lost foerever?