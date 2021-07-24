// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;
//Contract to vaccine aplication
contract Application{

    //struct of aplication
    struct Application_Vaccine{
        string date_application;
        uint256 age_people;
        string morbidity;
        //new changes for the certificate
        string name;
        string curp;
        string vaccine_brand;
        bool app;
    }



    //Mapping of string (curp agent people) to Application_Vaccine structure
    mapping(string => Application_Vaccine) public appVaccine;

    //Vaccine application event
    event ApplicationAdded(string _date_application, uint256 _age_people, string _morbidity, string _name, string _curp, string _vaccine_brand);

    //Function to vaccine apply
    function addApplication(
        string memory _date_application,
        uint256 _age_people,
        string memory _morbidity,
        string memory _name,
        string memory _curp,
        string memory _vaccine_brand
    ) public returns (bool _success){
        Application_Vaccine memory application_vaccine = Application_Vaccine(
            _date_application,
            _age_people,
            _morbidity,
            _name,
            _curp,
            _vaccine_brand,
            true
        );

        appVaccine[_curp] = application_vaccine;


        emit ApplicationAdded(_date_application, _age_people, _morbidity, _name, _curp, _vaccine_brand);
        _success = true;
    }



    function viewVaccination(string memory _curp) public view returns(string memory _name, string memory _date_application, string memory _vaccine_brand){
        Application_Vaccine memory application_vaccine = appVaccine[_curp];
        _name               = application_vaccine.name;
        _curp               = application_vaccine.curp;
        _date_application   = application_vaccine.date_application;
        _vaccine_brand      = application_vaccine.vaccine_brand;
    }
}