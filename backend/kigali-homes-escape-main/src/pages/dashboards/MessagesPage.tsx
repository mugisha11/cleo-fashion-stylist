import { useState, useRef, useEffect } from 'react';
import { Send, Search, Phone, Video, MoreVertical, Paperclip, Smile, ChevronLeft, Building2 } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Separator } from '@/components/ui/separator';
import { useAuth } from '@/contexts/AuthContext';
import DashboardLayout from '@/components/DashboardLayout';
import { cn } from '@/lib/utils';

interface Message {
  id: string;
  senderId: string;
  text: string;
  time: string;
  read: boolean;
}

interface Conversation {
  id: string;
  contact: {
    id: string;
    name: string;
    avatar: string;
    role: string;
    online: boolean;
  };
  property?: string;
  lastMessage: string;
  lastTime: string;
  unread: number;
  messages: Message[];
}

const mockConversations: Conversation[] = [
  {
    id: 'c1',
    contact: { id: 'u2', name: 'Jean Baptiste', avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100', role: 'Agent', online: true },
    property: 'Modern Villa in Nyarutarama',
    lastMessage: 'Yes, the villa is still available for viewing this weekend.',
    lastTime: '2 min ago',
    unread: 2,
    messages: [
      { id: 'm1', senderId: 'me', text: 'Hi! I\'m interested in the Modern Villa in Nyarutarama. Is it still available?', time: '10:30 AM', read: true },
      { id: 'm2', senderId: 'u2', text: 'Hello! Yes, the property is still available. Would you like to schedule a viewing?', time: '10:32 AM', read: true },
      { id: 'm3', senderId: 'me', text: 'That would be great! Is this weekend possible?', time: '10:35 AM', read: true },
      { id: 'm4', senderId: 'u2', text: 'Yes, the villa is still available for viewing this weekend.', time: '10:36 AM', read: true },
      { id: 'm5', senderId: 'u2', text: 'Saturday at 10 AM or Sunday at 2 PM — which works best for you?', time: '10:36 AM', read: false },
    ],
  },
  {
    id: 'c2',
    contact: { id: 'u3', name: 'Amina Kamanzi', avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100', role: 'Host', online: true },
    property: '3BR Apartment in Kacyiru',
    lastMessage: 'The rent includes water and security. Let me know if you need more details.',
    lastTime: '1 hour ago',
    unread: 1,
    messages: [
      { id: 'm6', senderId: 'me', text: 'Hello Amina, does the rent for the Kacyiru apartment include utilities?', time: '9:15 AM', read: true },
      { id: 'm7', senderId: 'u3', text: 'The rent includes water and security. Let me know if you need more details.', time: '9:45 AM', read: false },
    ],
  },
  {
    id: 'c3',
    contact: { id: 'u4', name: 'Patrick Mugisha', avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100', role: 'Client', online: false },
    property: 'Luxury Penthouse in Kimihurura',
    lastMessage: 'Thank you for the information. I\'ll get back to you soon.',
    lastTime: 'Yesterday',
    unread: 0,
    messages: [
      { id: 'm8', senderId: 'u4', text: 'Hi, I saw the penthouse listing. What\'s the earliest move-in date?', time: 'Yesterday 3:00 PM', read: true },
      { id: 'm9', senderId: 'me', text: 'Hi Patrick! The penthouse is available from April 1st. Would you like to visit?', time: 'Yesterday 3:15 PM', read: true },
      { id: 'm10', senderId: 'u4', text: 'Thank you for the information. I\'ll get back to you soon.', time: 'Yesterday 3:30 PM', read: true },
    ],
  },
  {
    id: 'c4',
    contact: { id: 'u5', name: 'Grace Uwamahoro', avatar: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=100', role: 'Agent', online: false },
    property: 'Family Home in Gacuriro',
    lastMessage: 'I\'ve sent you the floor plan. Check your email.',
    lastTime: '2 days ago',
    unread: 0,
    messages: [
      { id: 'm11', senderId: 'me', text: 'Do you have floor plans for the Gacuriro house?', time: '2 days ago 11:00 AM', read: true },
      { id: 'm12', senderId: 'u5', text: 'I\'ve sent you the floor plan. Check your email.', time: '2 days ago 11:30 AM', read: true },
    ],
  },
  {
    id: 'c5',
    contact: { id: 'u6', name: 'David Nkurunziza', avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100', role: 'Client', online: true },
    lastMessage: 'Looking for a 2BR apartment under 500K RWF/mo. Any suggestions?',
    lastTime: '3 days ago',
    unread: 0,
    messages: [
      { id: 'm13', senderId: 'u6', text: 'Looking for a 2BR apartment under 500K RWF/mo. Any suggestions?', time: '3 days ago 2:00 PM', read: true },
      { id: 'm14', senderId: 'me', text: 'Hi David! I have a few options in Kacyiru and Kibagabaga. Let me send you the details.', time: '3 days ago 2:30 PM', read: true },
    ],
  },
];

export default function MessagesPage() {
  const { user } = useAuth();
  const [conversations, setConversations] = useState(mockConversations);
  const [activeConvoId, setActiveConvoId] = useState<string | null>(null);
  const [newMessage, setNewMessage] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const activeConvo = conversations.find((c) => c.id === activeConvoId) ?? null;

  const filtered = conversations.filter(
    (c) =>
      c.contact.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (c.property?.toLowerCase().includes(searchQuery.toLowerCase()) ?? false)
  );

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [activeConvo?.messages.length]);

  const sendMessage = () => {
    if (!newMessage.trim() || !activeConvoId) return;
    const msg: Message = {
      id: `m-${Date.now()}`,
      senderId: 'me',
      text: newMessage.trim(),
      time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      read: false,
    };
    setConversations((prev) =>
      prev.map((c) =>
        c.id === activeConvoId
          ? { ...c, messages: [...c.messages, msg], lastMessage: msg.text, lastTime: 'Just now' }
          : c
      )
    );
    setNewMessage('');
  };

  const totalUnread = conversations.reduce((s, c) => s + c.unread, 0);

  return (
    <DashboardLayout>
      <div className="h-[calc(100vh-8.5rem)] flex rounded-2xl border border-border overflow-hidden bg-card">
        {/* Conversation List */}
        <div className={cn(
          'w-full md:w-80 lg:w-96 border-r border-border flex flex-col shrink-0 bg-card',
          activeConvoId && 'hidden md:flex'
        )}>
          {/* Search Header */}
          <div className="p-4 space-y-3">
            <div className="flex items-center justify-between">
              <div>
                <h2 className="text-lg font-bold">Messages</h2>
                {totalUnread > 0 && (
                  <p className="text-xs text-muted-foreground">{totalUnread} unread</p>
                )}
              </div>
            </div>
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
              <Input
                placeholder="Search conversations..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="pl-9 h-9 rounded-xl bg-muted/50 border-0"
              />
            </div>
          </div>

          <Separator />

          {/* Conversation Items */}
          <ScrollArea className="flex-1">
            <div className="divide-y divide-border/50">
              {filtered.map((convo) => (
                <button
                  key={convo.id}
                  onClick={() => {
                    setActiveConvoId(convo.id);
                    setConversations((prev) =>
                      prev.map((c) => (c.id === convo.id ? { ...c, unread: 0 } : c))
                    );
                  }}
                  className={cn(
                    'w-full flex items-start gap-3 p-4 text-left transition-colors hover:bg-accent/50',
                    activeConvoId === convo.id && 'bg-accent'
                  )}
                >
                  <div className="relative shrink-0">
                    <Avatar className="h-11 w-11">
                      <AvatarImage src={convo.contact.avatar} />
                      <AvatarFallback>{convo.contact.name.charAt(0)}</AvatarFallback>
                    </Avatar>
                    {convo.contact.online && (
                      <span className="absolute bottom-0 right-0 w-3 h-3 bg-chart-2 border-2 border-card rounded-full" />
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-2">
                      <span className="text-sm font-semibold truncate">{convo.contact.name}</span>
                      <span className="text-[10px] text-muted-foreground shrink-0">{convo.lastTime}</span>
                    </div>
                    {convo.property && (
                      <p className="text-[10px] text-primary font-medium flex items-center gap-1 mt-0.5">
                        <Building2 className="w-3 h-3" />
                        {convo.property}
                      </p>
                    )}
                    <p className="text-xs text-muted-foreground truncate mt-0.5">{convo.lastMessage}</p>
                  </div>
                  {convo.unread > 0 && (
                    <Badge className="shrink-0 h-5 min-w-5 flex items-center justify-center text-[10px] rounded-full">
                      {convo.unread}
                    </Badge>
                  )}
                </button>
              ))}
            </div>
          </ScrollArea>
        </div>

        {/* Chat Area */}
        {activeConvo ? (
          <div className={cn('flex-1 flex flex-col min-w-0', !activeConvoId && 'hidden md:flex')}>
            {/* Chat Header */}
            <div className="h-16 px-4 flex items-center justify-between border-b border-border shrink-0">
              <div className="flex items-center gap-3">
                <button onClick={() => setActiveConvoId(null)} className="md:hidden p-1 -ml-1">
                  <ChevronLeft className="w-5 h-5" />
                </button>
                <div className="relative">
                  <Avatar className="h-9 w-9">
                    <AvatarImage src={activeConvo.contact.avatar} />
                    <AvatarFallback>{activeConvo.contact.name.charAt(0)}</AvatarFallback>
                  </Avatar>
                  {activeConvo.contact.online && (
                    <span className="absolute bottom-0 right-0 w-2.5 h-2.5 bg-chart-2 border-2 border-card rounded-full" />
                  )}
                </div>
                <div>
                  <p className="text-sm font-semibold">{activeConvo.contact.name}</p>
                  <p className="text-[10px] text-muted-foreground">
                    {activeConvo.contact.online ? 'Online' : 'Offline'} · {activeConvo.contact.role}
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-1">
                <Button variant="ghost" size="icon" className="h-8 w-8"><Phone className="w-4 h-4" /></Button>
                <Button variant="ghost" size="icon" className="h-8 w-8"><Video className="w-4 h-4" /></Button>
                <Button variant="ghost" size="icon" className="h-8 w-8"><MoreVertical className="w-4 h-4" /></Button>
              </div>
            </div>

            {/* Property Context Bar */}
            {activeConvo.property && (
              <div className="px-4 py-2 bg-primary/5 border-b border-border flex items-center gap-2 text-xs">
                <Building2 className="w-3.5 h-3.5 text-primary" />
                <span className="font-medium text-primary">Re: {activeConvo.property}</span>
              </div>
            )}

            {/* Messages */}
            <ScrollArea className="flex-1 px-4">
              <div className="py-4 space-y-3 max-w-2xl mx-auto">
                {activeConvo.messages.map((msg) => {
                  const isMe = msg.senderId === 'me';
                  return (
                    <div key={msg.id} className={cn('flex', isMe ? 'justify-end' : 'justify-start')}>
                      <div className={cn(
                        'max-w-[75%] rounded-2xl px-4 py-2.5 text-sm',
                        isMe
                          ? 'bg-primary text-primary-foreground rounded-br-md'
                          : 'bg-muted text-foreground rounded-bl-md'
                      )}>
                        <p>{msg.text}</p>
                        <p className={cn(
                          'text-[10px] mt-1',
                          isMe ? 'text-primary-foreground/70' : 'text-muted-foreground'
                        )}>{msg.time}</p>
                      </div>
                    </div>
                  );
                })}
                <div ref={messagesEndRef} />
              </div>
            </ScrollArea>

            {/* Input Area */}
            <div className="p-3 border-t border-border">
              <div className="flex items-center gap-2 max-w-2xl mx-auto">
                <Button variant="ghost" size="icon" className="h-9 w-9 shrink-0">
                  <Paperclip className="w-4 h-4" />
                </Button>
                <Input
                  placeholder="Type a message..."
                  value={newMessage}
                  onChange={(e) => setNewMessage(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && !e.shiftKey && (e.preventDefault(), sendMessage())}
                  className="rounded-xl bg-muted/50 border-0 h-10"
                />
                <Button variant="ghost" size="icon" className="h-9 w-9 shrink-0">
                  <Smile className="w-4 h-4" />
                </Button>
                <Button
                  size="icon"
                  className="h-9 w-9 rounded-xl shrink-0"
                  onClick={sendMessage}
                  disabled={!newMessage.trim()}
                >
                  <Send className="w-4 h-4" />
                </Button>
              </div>
            </div>
          </div>
        ) : (
          <div className="hidden md:flex flex-1 items-center justify-center text-center p-8">
            <div>
              <div className="w-16 h-16 rounded-2xl bg-primary/10 flex items-center justify-center mx-auto mb-4">
                <Send className="w-7 h-7 text-primary" />
              </div>
              <h3 className="text-lg font-semibold mb-2">Your Messages</h3>
              <p className="text-sm text-muted-foreground max-w-xs">
                Select a conversation to start chatting with agents, hosts, or clients about properties.
              </p>
            </div>
          </div>
        )}
      </div>
    </DashboardLayout>
  );
}
