#########################################################################
#  OpenKore - Network subsystem
#  This module contains functions for sending messages to the server.
#
#  This software is open source, licensed under the GNU General Public
#  License, version 2.
#  Basically, this means that you're allowed to modify and distribute
#  this software. However, if you distribute modified versions, you MUST
#  also distribute the source code.
#  See http://www.gnu.org/licenses/gpl.html for the full license.
#########################################################################
# tRO (Thai) for 2008-09-16Ragexe12_Th
# Servertype overview: http://wiki.openkore.com/index.php/ServerType
package Network::Send::twRO;

use strict;
use Globals;
use Network::Send::ServerType0;
use base qw(Network::Send::ServerType0);
use Log qw(error debug);
use I18N qw(stringToBytes);
use Utils qw(getTickCount getHex getCoordString);
use Math::BigInt;

sub new {
	my ($class) = @_;
	my $self = $class->SUPER::new(@_);
	$self->{char_create_version} = 1;

	my %packets = (
		'0369' => ['actor_action', 'a4 C', [qw(targetID type)]],
		'0360' => ['buy_bulk_request', 'a4', [qw(ID)]],
		'0868' => ['item_drop', 'v2', [qw(index amount)]],
		'0872' => ['friend_request', 'a*', [qw(username)]],
		'0957' => ['homunculus_command', 'v C', [qw(commandType, commandID)]],
		'0880' => ['actor_look_at', 'v C', [qw(head body)]],
		'0362' => ['map_login', 'a4 a4 a4 V C', [qw(accountID charID sessionID tick sex)]],
		'0437' => ['character_move','a3', [qw(coords)]],
		'0A68' => ['party_join_request_by_name', 'Z24', [qw(partyName)]],
		'096A' => ['actor_info_request', 'a4', [qw(ID)]],
		'02C4' => ['skill_use', 'v2 a4', [qw(lv skillID targetID)]],
		'0438' => ['skill_use_location', 'v4', [qw(lv skillID x y)]],
		'087E' => ['storage_item_add', 'v V', [qw(index amount)]],
		'086E' => ['storage_item_remove', 'v V', [qw(index amount)]],
		'094A' => ['storage_password'],
		'035F' => ['sync', 'V', [qw(time)]],
		'07EC' => ['item_take', 'a4', [qw(ID)]],
		
		'0368' => ['actor_name_request', 'a4', [qw(ID)]],
		'0970' => ['char_create', 'a24 C v2', [qw(name, slot, hair_style, hair_color)]],
		'07D7' => ['party_setting', 'V C2', [qw(exp itemPickup itemDivision)]],
		'0801' => ['buy_bulk_vender', 'x2 a4 a4 a*', [qw(venderID venderCID itemInfo)]],
		'0998' => ['send_equip', 'v V', [qw(index type)]],
		'0064' => ['master_login', 'V Z24 a24 C', [qw(version username password_rijndael master_version)]]
		);
	$self->{packet_list}{$_} = $packets{$_} for keys %packets;

	
	my %handlers = qw(
		actor_action 0369
		buy_bulk_request 0360
		item_drop 0868
		friend_request 0872
		homunculus_command 0957
		actor_look_at 0880
		map_login 0362
		character_move 0437
		party_join_request_by_name 0A68
		actor_info_request 096A
		skill_use 02C4
		skill_use_location 0438
		storage_item_add 087E
		storage_item_remove 086E
		storage_password 094A
		sync 035F
		item_take 07EC
		
		actor_name_request 0368
		char_create 0970
		party_setting 07D7
		buy_bulk_vender 0801
		send_equip 0998
	);

	$self->{packet_lut}{$_} = $handlers{$_} for keys %handlers;
	$self->cryptKeys(0x545D44FA,0x3F945ADE,0x1C4D2334);

	$self->{sell_mode} = 0;
	return $self;
}
sub sendSync {
	my ($self, $initialSync) = @_;
	# XKore mode 1 lets the client take care of syncing.
	return if ($self->{net}->version == 1);

	$self->sendToServer($self->reconstruct({switch => 'sync'}));
	debug "Sent Sync\n", "sendPacket", 2;
	
	if ($ai_v{temp}{gameguard} && (time - $timeout{gameguard_request}{time} > 120)) {
		undef $ai_v{temp}{gameguard};
		$messageSender->sendRestart(1);
	}
}
sub sendMove {
	my $self = shift;

	# The server won't let us move until we send the sell complete packet.
	$self->sendSellComplete if $self->{sell_mode};

	$self->SUPER::sendMove(@_);
}
sub sendSellComplete {
	my ($self) = @_;
	$self->sendToServer(pack 'C*', 0xD4, 0x09);
	$self->{sell_mode} = 0;
}
sub sendCharCreate {
	my ($self, $slot, $name, $hair_style, $hair_color) = @_;

	my $msg = pack('C2 a24 C v2', 0x70, 0x09, stringToBytes($name), $slot, $hair_color, $hair_style);
	$self->sendToServer($msg);
	debug "Sent sendCharCreate\n", "sendPacket", 2;
}

1;