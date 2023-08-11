// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EntregaDePremios is Ownable {
    struct Premio {
        address token;
        uint256 cantidad;
        bool reclamado;
    }

    event PremioAsignado(
        address indexed ganador,
        address token,
        uint256 cantidad
    );

    mapping(address => Premio[]) private premios;

    function depositar(address token, uint256 cantidad) public onlyOwner {
        require(
            IERC20(token).transferFrom(msg.sender, address(this), cantidad),
            "La transferencia fallo"
        );
    }

    function asignarPremio(
        address ganador,
        address token,
        uint256 cantidad
    ) public onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(
            balance >= cantidad,
            "No hay suficientes fondos para cubrir el premio"
        );

        premios[ganador].push(Premio(token, cantidad, false));

        emit PremioAsignado(ganador, token, cantidad);
    }

    function reclamarPremio() public {
        uint256 totalPremios = premios[msg.sender].length;
        require(totalPremios > 0, "No tienes premios asignados");

        for (uint256 i = 0; i < totalPremios; i++) {
            Premio storage premio = premios[msg.sender][i];
            if (premio.reclamado) continue;

            uint256 balance = IERC20(premio.token).balanceOf(address(this));
            require(
                balance >= premio.cantidad,
                "No hay suficientes fondos para pagar el premio"
            );

            premio.reclamado = true;

            require(
                IERC20(premio.token).transfer(msg.sender, premio.cantidad),
                "La transferencia fallo"
            );
        }
    }

    function obtenerPremios(
        address ganador
    ) public view returns (Premio[] memory) {
        return premios[ganador];
    }

    function obtenerPremiosNoReclamados(
        address ganador
    ) public view returns (Premio[] memory) {
        Premio[] storage todosLosPremios = premios[ganador];

        uint256 cantidadNoReclamados = 0;
        for (uint256 i = 0; i < todosLosPremios.length; i++) {
            if (!todosLosPremios[i].reclamado) {
                cantidadNoReclamados++;
            }
        }

        Premio[] memory premiosNoReclamados = new Premio[](
            cantidadNoReclamados
        );

        uint256 indice = 0;
        for (uint256 i = 0; i < todosLosPremios.length; i++) {
            if (!todosLosPremios[i].reclamado) {
                premiosNoReclamados[indice] = todosLosPremios[i];
                indice++;
            }
        }

        return premiosNoReclamados;
    }

    function tienePremiosNoReclamados(
        address ganador
    ) public view returns (bool) {
        Premio[] storage premiosGanador = premios[ganador];
        for (uint256 i = 0; i < premiosGanador.length; i++) {
            if (!premiosGanador[i].reclamado) {
                return true;
            }
        }
        return false;
    }
}
