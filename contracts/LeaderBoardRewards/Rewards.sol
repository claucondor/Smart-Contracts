// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract EntregaDePremios is Ownable{
    // Define una estructura para almacenar información sobre un premio
    struct Premio {
        address token;
        uint256 cantidad;
        bool reclamado;
    }

    event PremioAsignado(address indexed ganador, address token, uint256 cantidad);

    mapping(address => Premio[]) private premios;

    function depositar(address token, uint256 cantidad) public onlyOwner{
        require(IERC20(token).transferFrom(msg.sender, address(this), cantidad), "La transferencia fallo");
    }

    function asignarPremio(address ganador, address token, uint256 cantidad) public onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance >= cantidad, "No hay suficientes fondos para cubrir el premio");

        // Asigna el premio al ganador agregándolo a la lista de premios
        premios[ganador].push(Premio(token, cantidad, false));

        emit PremioAsignado(ganador, token, cantidad);
    }

    function reclamarPremio(uint256 indice) public {
        require(indice < premios[msg.sender].length, "Indice de premio invalido");
        Premio storage premio = premios[msg.sender][indice];
        require(premio.cantidad > 0, "No tienes un premio asignado");
        require(!premio.reclamado, "Ya has reclamado tu premio");

        uint256 balance = IERC20(premio.token).balanceOf(address(this));
        require(balance >= premio.cantidad, "No hay suficientes fondos para pagar el premio");

        premio.reclamado = true;
        require(IERC20(premio.token).transfer(msg.sender, premio.cantidad), "La transferencia fallo");
    }

        function obtenerPremios(address ganador) public view returns (Premio[] memory) {
        return premios[ganador];
    }
}