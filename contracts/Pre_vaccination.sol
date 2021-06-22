pragma solidity >=0.4.22 <0.9.0;

contract Pre_vaccination{

    struct Reg_vaccination{
        address _address_who_stores;
        string name;
        string curp;
        string tel;
    }

    //mapping of addres to Received struct
    mapping (string => Reg_vaccination) public mapPre_vaccination;

    //event to store the data of the previous vaccination record
    event Pre_reg(address indexed _address_who_stores, string _name, string _curp, string _tel);

    //function to add data of the previous vaccination record
    function add_pre_vaccination(address _address_who_stores, string memory _name, string memory _curp, string memory _tel) public returns (bool _success){

        Reg_vaccination memory reg_vaccination = Reg_vaccination(_address_who_stores, _name, _curp, _tel);

        mapPre_vaccination[_curp] = reg_vaccination;

        emit Pre_reg(_address_who_stores, _name, _curp, _tel);
        _success = true;
    }

    function viewRegistration(string memory _curp) public view returns(address _address_who_stores, string memory _name, string memory _tel){
        Reg_vaccination memory reg_vaccination = mapPre_vaccination[_curp];
        _address_who_stores = reg_vaccination._address_who_stores;
        _name = reg_vaccination.name;
        _tel = reg_vaccination.tel;
    }

}