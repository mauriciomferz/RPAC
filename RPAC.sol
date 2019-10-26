//pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

/* experimental ABIEncoderV2 is needed as it supports string [] as argument in a function

/**
* @title RPAC
* @author Mauricio Fernandez 
* It's an extended contract of Alberto Cuesta Cañada RBAC smartcontract
* https://hackernoon.com/role-based-access-control-for-the-ethereum-blockchain-bcc9dfbcfe5c
* permissions will be assigned to an address 
* @notice Implements runtime configurable  Role & Permission Access Control.
*/

contract Roles {
  
  event RoleCreated(uint256 role);
  event AuthorisationCreated (address account, uint256 role );
  event BearerAdded(address account, uint256 role);
  event BearerRemoved(address account, uint256 role);
  uint256 constant NO_ROLE = 0;
  
  /**
   * @notice A role, which will be used to group users.
   * @param description A description for the role.
   * @param admin The only role that can add or remove bearers from
   * this role. To have the role bearers to be also the role admins 
   * you should pass roles.length as the admin role.
   * @param bearers Addresses belonging to this role.
   */
    
  struct Role {
    string description;
    uint256 admin;
    mapping (address => bool) bearers;
  } 
 
  
  Role[] public roles;
  
  /* @notice The contract constructor, empty as of now.
   *
   */  
   constructor() public {
   addRootRole("NO_ROLE");
   
   }
   
   /**
   * @notice Create a new role that has itself as an admin. 
   * msg.sender is added as a bearer.
   * @param _roleDescription The description of the role created.
   * @return The role id.
   */
   
  function addRootRole(string memory _roleDescription) 
    public 
    returns(uint256)
  {
    uint256 role = addRole(_roleDescription, roles.length);
    roles[role].bearers[msg.sender] = true;
    emit BearerAdded(msg.sender, role);
  }
  
  /**
   * @notice Create a new role.
   * @param _roleDescription The description of the role created.
   * @param _admin The role that is allowed to add and remove
   * bearers from the role being created.
   * @return The role id.
   */
  
  
  function addRole(string memory _roleDescription, uint256 _admin)
    public 
    returns (uint256)
  {
    require(_admin <= roles.length, "Admin role doesn't exist.");
     uint256 role = roles.push(Role({ description: _roleDescription, admin: _admin})) - 1;
      // Initiliase the Permission contract.
    return role;
    
   
  }
  /**
   * @notice Retrieve the number of roles in the contract.
   * @dev The zero position in the roles array is reserved for
   * NO_ROLE and doesn't count towards this total.
   */
  
  function totalRoles() public  view
    returns(uint256)
  {
    return roles.length -1;
  }

  
  /**
   * @notice Verify whether an account is a bearer of a role
   * @param _account The account to verify.
   * @param _role The role to look into.
   * @return Whether the account is a bearer of the role.
   */
   
  function hasRole(address _account, uint256 _role)
    public
    view
    returns(bool )
    {
     return _role < roles.length && roles[_role].bearers[_account];
        
    }
 
  function eraseRoles () public returns(bool) 
    {
     delete roles;
     roles.push(Role({description: "No Role", admin: 0}));
     delete roles[0].bearers[msg.sender];
     return true;
    }    


  /**
   * @notice A method to add a bearer to a role
   * @param _account The account to add as a bearer.
   * @param _role The role to add the bearer to.
   */
  
  function addBearer(address _account, uint256 _role)
    public
   {
    require(
      _role < roles.length,
      "Role doesn't exist."
    );
    require(
      hasRole(msg.sender, roles[_role].admin),
      "User can't add bearers."
    );
    require(
      !hasRole(_account, _role),
      "Account is bearer of role."
    );
    roles[_role].bearers[_account] = true;
    emit BearerAdded(_account, _role);
   }
  
  /**
   * @notice A method to remove a bearer from a role
   * @param _account The account to remove as a bearer.
   * @param _role The role to remove the bearer from.
   */
  
  function removeBearer(address _account, uint256 _role)
    public
   {
    require(
      _role < roles.length,
      "Role doesn't exist."
    );
    require(
      hasRole(msg.sender, roles[_role].admin),
      "User can't remove bearers."
    );
    require(
      hasRole(_account, _role),
      "Account is not bearer of role."
    );
    delete roles[_role].bearers[_account];
    emit BearerRemoved(_account, _role);
   }
}   

/**
* @title RPAC
* @author Mauricio Fernandez 
* This is a new contract for Permissions assigned to an address
* The Role's owner (bearer address) assigns a role to a new address
* The address is granted access rights based on CRED Permissions
*/


contract Permissions {

  event PermissionSet ( address accountAddress, string[] permission_name);
  event PermissionDelete ( address accountAddress );
  
   struct Permission {
       address accountAddress;
       string [] permission_name;
       bool isAssigned;
       uint256 permissionpointerlist;
    }

  mapping ( address => Permission) accounts2permission ; 
  address [] public permissionlist;
  
  //address admin;
  //constructor () public 
  //{
  //  admin = msg.sender;
  //  isassigned (admin);
  // }
  
  function isassigned (address _accountAddress) public view returns (bool)
    {
        if(permissionlist.length == 0) return false;
        return (accounts2permission[_accountAddress].isAssigned);
    }

    /* List of permissions assign an to a specific address
    * Permissions are Create Read Update Erase
    * @ accountAddress is the address of associated to a Role 1:1 relation
    * @ Permission_name is an array of strings that contains any of the [(N)(N)] permissions where N = 4
    * @ isAssigned to verify if and accountAddress has Permission assigned to itself
    * permissionpointerlist reference of the position of an element in unordered list
    */
    
 function getCountpermissionlist () public view returns (uint entityCount)
    {
        return permissionlist.length;
    }

 function newPermissionset (address _accountAddress, string [] memory _permission_name) public returns(bool)
    {
        if(isassigned(_accountAddress)) revert ("address alreaddy exist");
        accounts2permission[_accountAddress].accountAddress = _accountAddress;
        accounts2permission[_accountAddress].permission_name = _permission_name;
        accounts2permission[_accountAddress].isAssigned = true;
        accounts2permission[_accountAddress].permissionpointerlist = permissionlist.push(_accountAddress);
        emit PermissionSet (_accountAddress, _permission_name);
        return true;
    }

 function updatePermissions (address _accountAddress, string[] memory _permission_name ) public returns(bool)
    {
        if(!isassigned(_accountAddress)) revert ();
        accounts2permission[_accountAddress].accountAddress = _accountAddress;
        accounts2permission[_accountAddress].permission_name = _permission_name;
        emit PermissionSet ( _accountAddress, _permission_name);
        return true;
    }
  
    
 function retrieveaccountpermissions (address _accountAddress) public view returns (string[] memory, bool)    {
        if(!isassigned(_accountAddress)) revert ();
        return (accounts2permission[_accountAddress].permission_name, true);
    }

 function deletePermission (address _accountAddress) external returns(bool) 
    {
        if(!isassigned(_accountAddress)) revert ();
        uint256 rowToDelete = accounts2permission[_accountAddress].permissionpointerlist;
        address keyToMove = permissionlist[permissionlist.length-1];
        permissionlist[rowToDelete] = keyToMove;
        accounts2permission[keyToMove].permissionpointerlist = rowToDelete;
        permissionlist.length--;
        emit PermissionDelete ( _accountAddress);
        return true;
    }
}   

ontract Addresses2Roles is Roles,Permissions {
    
    // This struct only has only one Type
    // ridentfier is an array of integeres related to RoleId
    // it allows to assign one or more rolesId to a single adddress 
    // e.g address 0x0A may have one or more roles -> roleId = 1 , roleId= 2, roleId = 3
    
    
    struct Linking {
            uint256[] ridentifier;
    }
    
    // Public array of Struct 
    mapping (address => Linking) struct_linking;
    

    // _Roleid this arguments takes the RoleId created in contract Roles
    // _Accountaddrress this argument takes an address
    // verify if the account isassigned from contract Permissions
    // Verify the Roleid has a bearer from contract Roles
    // Make the link beteween RoleId and the address
    // Store the links in an array of  RolesId to Address(es)
    
    function linkage (uint256 _RoleId, address _accountAddress) public 
    returns (bool) {
        if (isassigned(_accountAddress) != true) revert ("Address does not have permissions yet");
             if (hasRole(_accountAddress,_RoleId) != true ) revert ("Address is not a bearer of the Role");
                 struct_linking[_accountAddress].ridentifier.push(_RoleId);
                 uint256 index =  struct_linking[_accountAddress].ridentifier.length;
                 struct_linking[_accountAddress].ridentifier[index - 1] = _RoleId;
                 
                //emit ()
    return true;
 
    }
        
        
    //  This function retrieves the RoleID for an address
    //  The address must have permissinos assigned to itself
    //  The address must have a roleID asssigned to itself
  
  
   function retrievetlength (address _accountAddress) public returns (uint256 ) {
       return struct_linking[_accountAddress].ridentifier.length;
   }
  
   function retrieveroleID (address _accountAddress) external returns (uint256 [] memory mapped_roles) {
     uint256 i;
       if ( _accountAddress != address(0x0)) revert ("Address is 0x0");
         if ( retrievetlength(_accountAddress) !=0 ) revert ("Return length is 0");
            for (i == 0 ; i <= retrievetlength(_accountAddress) - 1 ; ++i) {
             mapped_roles[i] = struct_linking[_accountAddress].ridentifier[i];
      }
    return mapped_roles;
    }
 }  
